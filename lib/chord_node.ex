defmodule ChordNode do
  use GenServer
  require Logger
  import Utils
  #  alias Transport.Client, as: RemoteNode
  use Transport.Client.Importer
  alias Storage

  @moduledoc """
  This module contains code implementation of the pseudocode specification in the Chord paper
  https://pdos.csail.mit.edu/papers/ton:chord/paper-ton.pdf
  """

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Some code used in this function is adapted from https://github.com/arriqaaq/chord/blob/master/node.go
  """
  @impl true
  def init(args) do
    node_name = String.to_atom("Node_#{args.id}")
    Process.flag(:trap_exit, Map.get(args, :trap_exit, true))

    state = %NodeState{
      node: %CNode{id: args.id, address: args.addr},
      storage_ref: Storage.init(node_name)
    }

    state = %{
      state
      | finger_fix_interval: Map.get(args, :fix_interval, state.finger_fix_interval)
    }

    state = %{
      state
      | predecessor_check_interval:
          Map.get(args, :pred_check_interval, state.predecessor_check_interval)
    }

    state = %{
      state
      | stabilization_interval: Map.get(args, :stabilize_interval, state.stabilization_interval)
    }

    Process.register(self(), node_name)
    #    StateAgent.put(:chord_node_ref, self())

    # Schedule stabilization task to be done later on
    schedule_stabilize(state.stabilization_interval)
    schedule_fix_fingers(state.finger_fix_interval)
    #    Logger.info("Node #{args.id} initialised")
    {:ok, state}
  end

  #  @impl true
  #  def terminate(reason, state) do
  #    case reason do
  #      {:shutdown, :ungraceful} ->
  #        String.to_atom("Node_#{state.node.id}") |> Process.unregister()
  #
  #      _ ->
  #        String.to_atom("Node_#{state.node.id}") |> Process.unregister()
  #
  #        if state.finger[1] != state.node do
  #          # transfer all keys to successor
  #          records = Storage.get_all(state.storage_ref)
  #
  #          if length(records) > 0 do
  #            RemoteNode.put(state.finger[1], records)
  #
  #            Storage.delete_record_range(
  #              state.storage_ref,
  #              Enum.map(records, fn r -> elem(r, 0) end)
  #            )
  #          end
  #
  #          RemoteNode.notify_departure(
  #            state.finger[1],
  #            state.node,
  #            state.predecessor,
  #            state.finger[1]
  #          )
  #        end
  #
  #        if state.predecessor != nil do
  #          RemoteNode.notify_departure(
  #            state.predecessor,
  #            state.node,
  #            state.predecessor,
  #            state.finger[1]
  #          )
  #        end
  #    end
  #  end

  @impl true
  def handle_call(:create, _from, state) do
    # predecessor is nil by default in the NodeState struct
    state = %{state | predecessor: state.node, successor: state.node}
    #    Logger.info("Node #{state.node.id} has created a network")
    {:reply, :ok, update_successor(state.node, state)}
  end

  @impl true
  def handle_call({:join, existing_node}, _from, state) do
    # predecessor starts as nil by default when NodeState struct is initialised
    case RemoteNode.find_successor(existing_node, state.node, 0) do
      {:error, c} ->
#        Logger.error(c)
        {:reply, {:error, c}, state}

      {s, _} ->
        new_successor =
          if s.id < state.node.id do
            state.node
          else
            # tell remote that this node might be it's predecessor
            if state.node.id < existing_node.id, do: RemoteNode.notify(existing_node, state.node)
            s
          end

        #      IO.inspect("new successor for #{state.node.id} #{new_successor["id"]}")
        # node is it's own successor so predecessor for now will be existing node
        state =
          if new_successor.id == state.node.id,
            do: %{state | predecessor: existing_node},
            else: state

        #        Logger.info("Node #{state.node.id} successfully joined #{existing_node.id}")

        #        Logger.debug("Node #{state.node.id} join complete: successor #{new_successor.id}")
        {:reply, :ok, update_successor(new_successor, state)}
    end
  end

  @impl true
  def handle_call({:find_successor, nd, hops}, _from, state) do
    #    IO.inspect("sdfjh #{state.node.id} #{nd.id}")
    #    IO.inspect("p s #{state.predecessor.id} #{state.finger[1].id}")
    state =
      if state.predecessor == state.finger[1] and nd != state.node do
        update_successor(nd, state)
      else
        state
      end

    result = find_successor(nd, state, hops)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:lookup, key}, _from, state) do
    result = Utils.id_to_cnode(key) |> find_successor(state, 0)
    {:reply, result, state}
  end

  @impl true
  def handle_call(:predecessor, _from, state) do
    {:reply, state.predecessor, state}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    k_hash = generate_hash(key)

    cond do
      k_hash == state.node.id ->
        {:reply, Storage.get(state.storage_ref, key), state}

      state.predecessor != nil and k_hash == state.predecessor.id ->
        res = RemoteNode.get(state.predecessor, key)
        {:reply, res, state}

      true ->
        {succ, _} = find_successor(k_hash, state)
        res = RemoteNode.get(succ, key)
        {:reply, res, state}
    end
  end

  @impl true
  def handle_call({:put, record}, _from, state) do
    if is_list(record) do
      Storage.put(state.storage_ref, record)
    else
      k_hash = generate_hash(elem(record, 0))

      cond do
        k_hash == state.node.id ->
          Storage.put(state.storage_ref, record)

        state.predecessor != nil and k_hash == state.predecessor.id ->
          RemoteNode.put(state.predecessor, record)

        true ->
          {succ, _} = find_successor(Utils.id_to_cnode(k_hash), state)

          if succ == state.node do
            Storage.put(state.storage_ref, record)
          else
            RemoteNode.put(succ, record)
          end
      end
    end

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:key_count, _from, state) do
    {:reply, Storage.record_count(state.storage_ref), state}
  end

  # Handles message from n as n thinks it might be our predecessor.
  @impl true
  def handle_cast({:notify, n}, state) do
    #    IO.inspect("notif #{n.id} #{state.node.id}")
    pred = Utils.map2cnode(n)

    state =
      if state.predecessor == nil or
           in_closed_interval?(pred.id, state.predecessor.id, state.node.id) do
        #        Logger.debug("Node #{state.node.id}'s new predecessor is #{n.id}")
        %{state | predecessor: n}
      else
        state
      end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:notify_departure, n, pred, succ}, state) do
    #    Logger.info("Node #{n.id} is departing")

    cond do
      state.node.id > n.id ->
        # departing node is predecessor
        {:noreply, %{state | predecessor: pred}}

      true ->
        # departing node is successor
        {:noreply, update_successor(succ, state)}
    end
  end

  @impl true
  def handle_info(:stabilize, state) do
    if Application.get_env(:chord, :run_stabilizations, true) do
      x =
        if state.finger[1] == state.node do
          state.predecessor
        else
          case RemoteNode.predecessor(state.finger[1]) do
            {:error, _} ->
              #              Logger.error(msg)
              state.predecessor

            pred ->
              pred
          end
        end

      state =
        if x != nil and state.finger[1] != nil and
             in_closed_interval?(x.id, state.node.id, state.finger[1].id) do
          # move records that might belong to the new successor
          records = Storage.get_record_key_range(state.storage_ref, state.node.id, x)
          #          Logger.debug(records)
          if length(records) > 0 do
            RemoteNode.put(x, records)

            Storage.delete_record_range(
              state.storage_ref,
              Enum.map(records, fn r -> elem(r, 0) end)
            )

            #            Logger.debug("Node #{state.node.id} transferred keys to #{x.id}")
          end

          #          Logger.debug("Node #{state.node.id}'s new successor from stabilize is #{x.id}")
          update_successor(x, state)
        else
          state
        end

      RemoteNode.notify(state.finger[1], state.node)
      schedule_stabilize(state.stabilization_interval)
      {:noreply, state}
    else
      schedule_stabilize(state.stabilization_interval)
      {:noreply, state}
    end
  end

  @impl true
  def handle_info(:fix_fingers, state) do
    if Application.get_env(:chord, :run_stabilizations, true) do
      state = fix_fingers(state)
      schedule_fix_fingers(state.finger_fix_interval)
      {:noreply, state}
    else
      schedule_fix_fingers(state.finger_fix_interval)
      {:noreply, state}
    end
  end

  @impl true
  def handle_info(:check_predecessor, state) do
    state = check_predecessor(state)
    schedule_check_predecessor(state.predecessor_check_interval)
    {:noreply, state}
  end

  #  defp find_predecessor(id, state, n \\ state.node) do
  #    if in_half_closed_interval?(id, n, n.successor) == false do
  #      if n == state.node do
  #        n = closest_preceding_node(id, state)
  #      else
  #        n = "remote closest preceding finger"
  #      end
  #      n = 2
  #    end
  #  end

  defp find_successor(nd, state, hops \\ 0) do
    #    IO.inspect("#{state.node.id} #{state.finger[1].id} #{nd.id}")
    cond do
      state.finger[1] != nil and in_half_closed_interval?(nd.id, state.node.id, state.finger[1].id) ->
        {state.finger[1], hops}

      nd.id < state.node.id ->
        {state.finger[1], hops}

      true ->
        n = closest_preceding_node(nd.id, state)

        # This prevents a remote call looping back
        if n.id == state.node.id do
          {state.finger[1], hops}
        else
          case RemoteNode.find_successor(n, nd, hops + 1) do
            {:error, _} ->
#              Logger.error(msg)
              {state.finger[1], hops}

            {s, count} ->
              #              Logger.info("successor lookup | hops: #{count}")
              {s, count}
          end
        end
    end
  end

  @doc """
  Implements function from Fig.5 in Chord paper
  """
  def closest_preceding_node(id, state, i \\ -1)
  def closest_preceding_node(_, state, 0), do: state.node

  def closest_preceding_node(id, state, i) do
    i = if(i == -1, do: state.bit_size, else: i)

    if Map.has_key?(state.finger, i) and
         in_closed_interval?(state.finger[i].id, state.node.id, id) do
      state.finger[i]
    else
      closest_preceding_node(id, state, i - 1)
    end
  end

  defp schedule_stabilize(interval) do
    Process.send_after(self(), :stabilize, interval)
  end

  defp schedule_fix_fingers(interval) do
    Process.send_after(self(), :fix_fingers, interval)
  end

  defp schedule_check_predecessor(interval) do
    Process.send_after(self(), :check_predecessor, interval)
  end

  defp fix_fingers(state) do
    next = state.next_fix_finger + 1

    next =
      if next > state.bit_size do
        1
      else
        next
      end

    # finger[next] = find_successor
    finger_next = Utils.id_to_cnode(state.node.id + (:math.pow(2, next - 1) |> round))
    if finger_next == nil do
      %{state | next_fix_finger: next}
    else
      {resp, _} = find_successor(finger_next, state)
      updated_finger_table = Map.put(state.finger, next, resp)
      %{state | finger: updated_finger_table, next_fix_finger: next}
    end
  end

  @doc """
  Update the successor node with the new node value
  n.b: successor == finger[1]
  """
  def update_successor(n, state) do
    res =
      if is_struct(n) do
        n
      else
        %CNode{id: n["id"], address: n["address"]}
      end

    %{state | finger: %{state.finger | 1 => res}}
  end

  @doc """
  Called periodically. checks whether predecessor has failed
  """
  def check_predecessor(state) do
    {result, _} = RemoteNode.ping(state.predecessor)

    if result != :ok do
      %{state | predecessor: nil}
    else
      state
    end
  end
end
