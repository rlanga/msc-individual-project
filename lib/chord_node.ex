defmodule ChordNode do
  use GenServer
  alias Transport.Client, as: RemoteNode
  @moduledoc false


  def start_link(opts) do

    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Some code used in this function is adapted from https://github.com/arriqaaq/chord/blob/master/node.go
  """
  @impl true
  def init(args) do
    state = %NodeState{}

    nid = if Map.has_key?(args, :id) do
      args.id
    else
      args.addr
    end
    state = %{state | node: %CNode{id: generate_hash(nid), address: args.addr}}

#    Process.register(self(), String.to_atom("Node_#{state.node.id}"))
#    transport_spec = JSONRPC2.Servers.HTTP.child_spec(:http, Transport.Server, [port: args.port])
#    Supervisor.start_link(transport_spec, strategy: :one_for_one)
    StateAgent.put(:chord_node_ref, self())

    # Schedule stabilization task to be done later on
    schedule_stabilize(state.stabilization_interval)
    {:ok, state}
  end

  @impl true
  def handle_call(:create, _from, state) do
    # predecessor is nil by default in the NodeState struct
    {:reply, :ok, %{state | finger: [state.node]}}
  end

  @impl true
  def handle_call({:join, existing_node}, _from, state) do
    # predecessor starts as nil by default when NodeState struct is initialised
    {status, msg} = RemoteNode.find_successor(existing_node, state.node.id)
    if status == :ok do
      {:reply, :ok, update_successor(msg, state)}
    else
      {:reply, {status, msg}, state}
    end
  end

  @impl true
  def handle_call({:find_successor, id}, _from, state) do
    IO.inspect("sdfjh #{state.node.address}")
    res = find_successor(id, state)
    {:reply, res, state}
  end

  @impl true
  def handle_call({:predecessor}, _from, state) do
    #    GenServer.call(_closest, {:find_successor, id, sender})
    {:reply, hd(state.finger), state}
  end

#  def handle_call({:closest_preceding_finger, id}, _from, state) do
#    res = n
#    if Enum.member?(n+1..id-1, )
#    {:reply, :ok, state}
#  end

  # Handles message from n as n thinks it might be our predecessor.
  @impl true
  def handle_call({:notify, n}, _from, state) do
    state = if state.predecessor == nil or in_closed_interval?(n.id, state.predecessor.id, state.node.id) do
        %{state | predecessor: n}
      else
        state
    end
    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:stabilize, state) do
    x = RemoteNode.predecessor(state.predecessor)
    state = if in_closed_interval?(x, state.id, hd(state.finger)) do
        %{state | successor: x}
      else
        state
    end
    RemoteNode.notify(state.node)

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

  defp find_successor(id, state) do
    cond do
      in_half_closed_interval?(id, state.node.id, hd(state.finger).id) ->
        hd(state.finger)
      id < state.node.id ->
        hd(state.finger)
      true ->
        n = closest_preceding_node(id, state)
        IO.inspect(n)
        RemoteNode.find_successor(n, id)
    end
  end

  @doc """
  Implements function from Fig.5 in Chord paper
  """
  defp closest_preceding_node(id, state) do
    Enum.reverse(state.finger)
    |> Enum.find(state.node, fn f -> in_half_closed_interval?(f.id, state.node.id, id) end)
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
    {status, resp} = find_successor(state.node.id + (:math.pow(2, next-1) |> round), state)
    updated_finger_table = List.replace_at(state.finger, next, resp)
    %{state | finger: updated_finger_table, next_fix_finger: next}
  end

  @doc """
  Update the successor node with the new node value
  n.b: successor == finger[0]
  """
  defp update_successor(n, state) do
    %{state | finger: List.replace_at(state.finger, 0, n)}
  end

  @doc """
  Called periodically. checks whether predecessor has failed
  """
  defp check_predecessor(state) do
    {result, _} = RemoteNode.ping(state.predecessor)
    if result != :ok do
      %{state | predecessor: nil}
    else
      state
    end
  end

  defp in_closed_interval?(val, a, b) do
    val > a and val < b
  end

  @doc """
  Checks a value is in a half-closed interval (a,b]
  """
  defp in_half_closed_interval?(val, a, b) do
    val > a and val <= b
  end

  @doc """
  Performs the consistent hashing function using SHA-1
  """
  def generate_hash(data) do
    :crypto.hash(:sha, data)
    |> Base.encode16
    |> Integer.parse(16)
    |> elem(0)
  end
end