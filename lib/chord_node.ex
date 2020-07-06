defmodule ChordNode do
  @moduledoc false
  


  use GenServer
  alias Chord.Transport.Client, as: RemoteNode

#  def start_link(state, opts) do
#
#    GenServer.start_link(__MODULE__, state)
#  end

  @doc """
  Some code used in this function is adapted from https://github.com/arriqaaq/chord/blob/master/node.go
  """
  def init(args) do
    state = %NodeState{}
    nid = ""

    if Map.has_key?(args, :id) do
      nid = args.id
    else
      nid = args.addr
    end
    state = %{state | node: %CNode{id: generate_hash(nid)}}

    # Schedule stabilization task to be done later on
    stabilize(state.stabilization_interval)
    {:ok, state}
  end

  @impl true
  def handle_call(:create, state) do
    # predecessor is nil by default in the NodeState struct
    IO.inspect(state)
    {:reply, :ok, update_successor(state.node, state)}
  end

  @impl true
  def handle_call({:join, existing_node}, state) do
    # predecessor starts as nil by default when NodeState struct is initialised
    {status, msg} = RemoteNode.find_successor(existing_node)
    {:reply, :ok, update_successor(msg, state)}
  end

  @impl true
  def handle_call({:find_successor, id, sender}, _from, state) do
    {status, msg} = find_successor(id, state)
    {:reply, {:ok, msg}, state}
  end

  @impl true
  def handle_call({:find_predecessor, id, sender}, _from, state) do
    #    GenServer.call(_closest, {:find_successor, id, sender})
    {:reply, :ok, state}
  end

#  def handle_call({:closest_preceding_finger, id}, _from, state) do
#    res = n
#    if Enum.member?(n+1..id-1, )
#    {:reply, :ok, state}
#  end

  # Handles message from n as n thinks it might be our predecessor.
  @impl true
  def handle_cast({:notify, n}, state) do
    if state.predecessor == nil or in_closed_interval?(n.id, state.predecessor.id, state.node.id) do
      state = %{state | predecessor: n}
    end
    {:noreply, state}
  end

  @impl true
  def handle_info(:stabilize, state) do
    x = RemoteNode.find_predecessor(hd(state.finger))
    if in_closed_interval?(x, state.id, hd(state.finger)) do
      state = %{state | successor: x}
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

  defp find_predecessor(id, state, n \\ state.node) do
    if in_half_closed_interval?(id, n, n.successor) == false do
      if n == state.node do
        n = closest_preceding_node(id, state)
      else
        n = "remote closest preceding finger"
      end
      n = 2
    end
  end

  defp find_successor(id, state) do
    if in_half_closed_interval?(id, state.node.id, hd(state.finger).id) do
      hd(state.finger)
    else
      n = closest_preceding_node(id, state)
      RemoteNode.find_successor(n, id)
    end
  end

  @doc """
  Implements function from Fig.5 in Chord paper
  """
  defp closest_preceding_node(id, state) do
    Enum.reverse(state.finger)
    |> Enum.find(state.node, fn f -> in_half_closed_interval?(f.start, state.node.id, id) end)
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

  defp fix_fingers(state, next \\ 0) do
    next = next + 1
    if next > state.bit_size do
      next = 1
    end
    # finger[next] = find_successor
    {status, resp} = RemoteNode.find_successor(state.node.id + (:math.pow(2, next-1) |> round))
    updated_finger_table = List.replace_at(state.finger, next, resp)
    state = %{state | finger: updated_finger_table}
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
    {result, msg} = RemoteNode.ping(state.predecessor)
    if result != :ok do
      state = %{state | predecessor: nil}
    end
    state
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
  defp generate_hash(data) do
    :crypto.hash(:sha, data)
    |> Base.encode16
    |> Integer.parse(16)
    |> elem(0)
  end
end