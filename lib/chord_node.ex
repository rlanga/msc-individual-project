defmodule ChordNode do
  @moduledoc false
  


  use GenServer

  def start_link(state, opts) do

    GenServer.start_link(__MODULE__, state)
  end

  def init(state \\ %NodeState{}) do
    if state.id == nil do
      state = %{state | id: :crypto.hash(:sha, "node_name@IP") |> Base.encode16}
    end
    # Schedule stabilization task to be done later on
    stabilize(state.stabilization_interval)
    {:ok, state}
  end

  @impl true
  def handle_call(:create, state) do
    # predecessor is nil by default in the NodeState struct
    IO.inspect(state)
    {:reply, :ok, %{state | successor: state.id}}
  end

  @impl true
  def handle_call({:find_successor, id, sender}, _from, state) do
#    GenServer.call(_closest, {:find_successor, id, sender})
    if in_half_closed_interval?(id, state.id, state.successor) do
      1 # send state.successor back to sender
    else
      2
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
    if state.predecessor == nil or in_closed_interval?(n, state.predecessor, state.id) do
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

  defp stabilize(interval) do
    Process.send_after(self(), :stabilize, interval)
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
end