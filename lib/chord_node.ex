defmodule ChordNode do
  @moduledoc false
  


  use GenServer

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
    {:reply, :ok, %{state | successor: state.node}}
  end

  @impl true
  def handle_call({:find_successor, id, sender}, _from, state) do
#    GenServer.call(_closest, {:find_successor, id, sender})
    if in_half_closed_interval?(id, state.node.id, state.successor.id) do
      1 # send state.successor back to sender
    else
      2 #Enum.at
    end
    {:reply, :ok, state}
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
    x = state.successor # call find_predecessor on successor
    if in_closed_interval?(x, state.id, state.successor) do
      state = %{state | successor: x}
    end
    # successor.notify(state.id)

    stabilize(state.stabilization_interval)
    {:noreply, state}
  end

  def find_predecessor(id, state, n \\ state.node) do
    if in_half_closed_interval?(id, n, n.successor) == false do
      if n == state.node do
        n = closest_preceding_finger(id, state)
      else
        n = "remote closest preceding finger"
      end
      n = 2
    end
  end

  @doc """
  Implements function from Fig.4 in Chord paper
  """
  def closest_preceding_finger(id, state) do
    Enum.reverse(state.finger)
    |> Enum.find(state.node, fn f -> in_half_closed_interval?(f.start, state.node.id, id) end)
  end

  defp stabilize(interval) do
    Process.send_after(self(), :stabilize, interval)
  end

  defp fix_finger(state, next \\ 0) do
    next = next + 1
    if next > state.bit_size do
      next = 1
    end
    # finger[next] = find_successor
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