defmodule Transport.Simulation do
  @moduledoc """
  Transport layer methods to be used in simulations.
  Calls will be made to other node processes within Elixir
  """
  import Utils, only: [get_node_pid: 1]

  @spec ping(CNode.t()) :: {:ok, String.t()} | {:error, String.t()}
  def ping(n) do
    get_node_pid(n)
    |> case do
      nil -> {:error, "Peer down"}
      _ -> {:ok, "Peer #{n.id} still up"}
    end
  end

  @spec notify(CNode.t(), CNode.t()) :: {:ok, String.t()} | {:error, String.t()}
  def notify(n, pred) do
    get_node_pid(n)
    |> case do
      nil ->
        {:error, "notify failed"}

      pid ->
        GenServer.cast(pid, {:notify, pred})
        {:ok, "Peer #{n.id} notified"}
    end
  end

  @spec find_successor(CNode.t(), integer(), integer()) :: CNode.t() | {:error, String.t()}
  def find_successor(n, id, hops) do
    get_node_pid(n)
    |> case do
      nil ->
        {:error, "#{id.id} successor search failed"}

      pid ->
        GenServer.call(pid, {:find_successor, id, hops})
    end
  end

  @spec predecessor(CNode.t()) :: CNode.t() | {:error, String.t()}
  def predecessor(n) do
    get_node_pid(n)
    |> case do
      nil ->
        {:error, "predecessor search failed"}

      pid ->
        GenServer.call(pid, :predecessor)
    end
  end

  @spec get(CNode.t(), String.t()) :: any() | {:error, String.t()}
  def get(n, key) do
    get_node_pid(n)
    |> case do
      nil ->
        {:error, "Get operation failed"}

      pid ->
        GenServer.call(pid, {:get, key})
    end
  end

  @spec put(CNode.t(), tuple) :: any() | {:error, String.t()}
  def put(n, record) do
    get_node_pid(n)
    |> case do
      nil ->
        {:error, "Put operation failed"}

      pid ->
        GenServer.call(pid, {:put, record})
    end
  end

  @spec notify_departure(CNode.t(), CNode.t(), CNode.t(), CNode.t()) ::
          {:ok, any()} | {:error, String.t()}
  def notify_departure(dest, n, pred, succ) do
    get_node_pid(dest)
    |> case do
      nil ->
        {:error, "Departure notification failed"}

      pid ->
        GenServer.cast(pid, {:notify_departure, n, pred, succ})
        {:ok, "notified"}
    end
  end
end
