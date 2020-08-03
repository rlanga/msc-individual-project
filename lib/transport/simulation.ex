defmodule Transport.Simulation do
  @moduledoc """
  Transport layer methods to be used in simulations.
  Calls will be made to other node processes within Elixir
  """
  require Utils

  @spec ping(CNode.t()) :: {:ok, String.t()} | {:error, String.t()}
  def ping(n) do
    Utils.get_node_pid(n.id)
    |> case do
      nil -> {:error, "Peer #{n.id} down"}
       _ -> {:ok, "Peer #{n.id} still up"}
    end
  end

  @spec notify(CNode.t(), CNode.t()) :: {:ok, String.t()} | {:error, String.t()}
  def notify(n, pred) do
    Utils.get_node_pid(n.id)
    |> case do
      nil ->
        {:error, "Failed to notify #{n.id}"}
      pid ->
        GenServer.cast(pid, {:notify, pred})
        {:ok, "Peer #{n.id} notified"}
    end
  end

  @spec find_successor(CNode.t(), integer(), integer()) :: CNode.t() | {:error, String.t()}
  def find_successor(n, id, hops) do
    Utils.get_node_pid(n.id)
    |> case do
      nil ->
        {:error, "#{id} successor search failed at #{n.id}"}
      pid ->
        GenServer.call(pid, {:find_successor, id, hops})
    end
  end

  @spec predecessor(CNode.t()) :: CNode.t() | {:error, String.t()}
  def predecessor(n) do
    Utils.get_node_pid(n.id)
    |> case do
         nil ->
           {:error, "predecessor search failed at #{n.id}"}
         pid ->
           GenServer.call(pid, :predecessor)
       end
  end

  @spec get(CNode.t(), String.t()) :: any() | {:error, String.t()}
  def get(n, key) do
    Utils.get_node_pid(n.id)
    |> case do
         nil ->
           {:error, "Get operation from #{n.id} failed"}
         pid ->
           GenServer.call(pid, {:get, key})
       end
  end

  @spec put(CNode.t(), tuple) :: any() | {:error, String.t()}
  def put(n, record) do
    Utils.get_node_pid(n.id)
    |> case do
         nil ->
           {:error, "Put operation to #{n.id} failed"}
         pid ->
           GenServer.call(pid, {:put, record})
       end
  end

  @spec notify_departure(CNode.t(), CNode.t(), CNode.t(), CNode.t()) :: {:ok, any()} | {:error, String.t()}
  def notify_departure(dest, n, pred, succ) do
    Utils.get_node_pid(dest.id)
    |> case do
         nil ->
           {:error, "Departure notification to #{dest.id} failed"}
         pid ->
           GenServer.cast(pid, {:notify_departure, n, pred, succ})
           {:ok, "notified"}
       end
  end
end