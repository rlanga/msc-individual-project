defmodule ChordNode do
  use GenServer
  require Logger
  import Utils
  alias Transport.Client, as: RemoteNode
  alias Storage
  @moduledoc false


  def start_link(opts) do

    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Some code used in this function is adapted from https://github.com/arriqaaq/chord/blob/master/node.go
  """
  @impl true
  def init(args) do
    node_name = String.to_atom("Node_#{args.id}")
    state = %NodeState{node: %CNode{id: args.id, address: args.addr}, storage_ref: Storage.init(node_name)}

    Process.register(self(), node_name)
#    StateAgent.put(:chord_node_ref, self())

    # Schedule stabilization task to be done later on
    schedule_stabilize(state.stabilization_interval)
    Logger.info("Node #{args.id} initialised")
    {:ok, state}
  end

  @impl true
  def terminate(_reason, state) do
    if state.finger[1] != state.node do
      # transfer all keys to successor
      records = Storage.get_all(state.storage_ref)
      if length(records) > 0 do
        RemoteNode.put(state.finger[1], records)
        Storage.delete_record_range(state.storage_ref, Enum.map(records, fn r -> elem(r, 0) end))
      end
      RemoteNode.notify_departure(state.finger[1], state.node, state.predecessor, state.finger[1])
    end
    if state.predecessor != nil do
      RemoteNode.notify_departure(state.predecessor, state.node, state.predecessor, state.finger[1])
    end
  end

  @impl true
  def handle_call(:create, _from, state) do
    # predecessor is nil by default in the NodeState struct
    state = %{state | predecessor: state.node, successor: state.node}
    Logger.info("New chord network created!")
    {:reply, :ok, update_successor(state.node, state)}
  end

  @impl true
  def handle_call({:join, existing_node}, _from, state) do
    # predecessor starts as nil by default when NodeState struct is initialised
    case RemoteNode.find_successor(existing_node, state.node) do
      {:error, c} ->
        Logger.error(c)
        {:reply, {:error, c}, state}
      s ->
        new_successor = if s.id < state.node.id do
          state.node
        else
          # tell remote that this node might be it's predecessor
          if state.node.id < existing_node.id, do: RemoteNode.notify(existing_node, state.node)
          s
        end

        #      IO.inspect("new successor for #{state.node.id} #{new_successor["id"]}")
        # node is it's own successor so predecessor for now will be existing node
        state = if new_successor.id == state.node.id, do: %{state | predecessor: existing_node}, else: state
        Logger.info("Node #{state.node.id} successfully joined #{existing_node.id}")
        Logger.debug("Node #{state.node.id} join complete: successor #{new_successor.id}")
        {:reply, :ok, update_successor(new_successor, state)}
    end
  end

  @impl true
  def handle_call({:find_successor, nd}, _from, state) do
#    IO.inspect("sdfjh #{state.node.id} #{nd.id}")
#    IO.inspect("p s #{state.predecessor.id} #{state.finger[1].id}")
    state = if state.predecessor == state.finger[1] and nd != state.node do
            update_successor(nd, state)
          else
            state
          end
    result = find_successor(nd, state)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:predecessor}, _from, state) do
    {:reply, state.predecessor, state}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    k_hash = generate_hash(key)
    cond do
      k_hash == state.node.id ->
        {:reply, Storage.get(state.storage_ref, key), state}
      k_hash == state.predecessor.id ->
        res = RemoteNode.get(state.predecessor, key)
        {:reply, res, state}
      true ->
        succ = find_successor(k_hash, state)
        res = RemoteNode.get(succ, key)
        {:reply, res, state}
    end
  end

  @impl true
  def handle_call({:put, record}, _from, state) do
    k_hash = generate_hash(elem(record, 0))
    cond do
      k_hash == state.node.id ->
        Storage.put(state.storage_ref, record)
        {:reply, :ok, state}
      k_hash == state.predecessor.id ->
        RemoteNode.put(state.predecessor, record)
        {:reply, :ok, state}
      true ->
        succ = find_successor(k_hash, state)
        RemoteNode.put(succ, record)
        {:reply, :ok, state}
    end
  end

#  def handle_call({:closest_preceding_finger, id}, _from, state) do
#    res = n
#    if Enum.member?(n+1..id-1, )
#    {:reply, :ok, state}
#  end

  # Handles message from n as n thinks it might be our predecessor.
  @impl true
  def handle_cast({:notify, n}, state) do
#    IO.inspect("notif #{n.id} #{state.node.id}")
    pred = if is_struct(n), do: n, else: %CNode{id: n["id"], address: n["address"]}
    state = if state.predecessor == nil or in_closed_interval?(pred.id, state.predecessor.id, state.node.id) do
        Logger.debug("Notify received: New predecessor is #{n.id}")
        %{state | predecessor: n}
      else
        state
    end
    {:noreply, state}
  end

  @impl true
  def handle_cast({:notify_departure, n, pred, succ}, state) do
    Logger.info("Node #{n.id} is departing")
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
    x = if state.finger[1] == state.node do
        state.predecessor
      else
        case RemoteNode.predecessor(state.finger[1]) do
          {:error, msg} ->
            Logger.error(msg)
            state.predecessor
          pred -> pred
        end
      end
    state = if in_closed_interval?(x.id, state.node.id, state.finger[1].id) do
        # move records that might belong to the new successor
        records = Storage.get_record_key_range(state.storage_ref, state.node.id, x)
        if length(records) > 0 do
          RemoteNode.put(x, records)
          Storage.delete_record_range(state.storage_ref, Enum.map(records, fn r -> elem(r, 0) end))
        end
        Logger.debug("Node #{state.node.id}'s new successor from stabilize is #{x.id}")
        update_successor(x, state)
      else
        state
    end
    RemoteNode.notify(state.finger[1], state.node)

    schedule_stabilize(state.stabilization_interval)
    {:noreply, state}
  end

  @impl true
  def handle_info(:fix_fingers, state) do
    state = fix_fingers(state)
    schedule_fix_fingers(state.finger_fix_interval)
    {:noreply, state}
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

  defp find_successor(nd, state) do
#    IO.inspect("#{state.node.id} #{state.finger[1].id} #{nd.id}")
    cond do
      in_half_closed_interval?(nd.id, state.node.id, state.finger[1].id) ->
        state.finger[1]
      nd < state.node.id ->
        state.finger[1]
      true ->
        n = closest_preceding_node(nd.id, state)

        # This prevents a remote call looping back
        if n.id == state.node.id do
          state.finger[1]
        else
          case RemoteNode.find_successor(n, nd) do
            {:error, msg} ->
              Logger.error(msg)
              state.finger[1]
            s -> s
          end
        end
    end
  end

  @doc """
  Implements function from Fig.5 in Chord paper
  """
#  defp closest_preceding_node(id, state) do
#    Map.keys(state.finger)
#    |> Enum.reverse()
#    |> Enum.find(state.node, fn f -> in_half_closed_interval?(f.id, state.node.id, id) end)
#  end
  def closest_preceding_node(id, state, i \\ -1)
  def closest_preceding_node(_, state, 0), do: state.node
  def closest_preceding_node(id, state, i) do
    i = if(i == -1, do: state.bit_size, else: i)

    if Map.has_key?(state.finger, i) and in_closed_interval?(state.finger[i].id, state.node.id, id) do
      state.finger[i]
    else
      closest_preceding_node(id, state, i-1)
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
    next = if next > state.bit_size do
        1
      else
        next
    end
    # finger[next] = find_successor
    {_, resp} = find_successor(state.node.id + (:math.pow(2, next-1) |> round), state)
    updated_finger_table = %{state.finger | next => resp}
    %{state | finger: updated_finger_table, next_fix_finger: next}
  end

  @doc """
  Update the successor node with the new node value
  n.b: successor == finger[1]
  """
  def update_successor(n, state) do
    res = if is_struct(n) do
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