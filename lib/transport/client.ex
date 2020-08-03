defmodule Transport.Client do
  @moduledoc """
  Transport layer used to communicate with nodes in an external network
  """
  alias JSONRPC2.Clients.HTTP

  @spec ping(CNode.t()) :: {:ok, String.t()} | {:error, String.t()}
  def ping(n) do
    case HTTP.call(n.address, "ping", [n.id]) do
      {:ok, "pong"} -> {:ok, "Peer #{n.id} still up"}
      _ -> {:error, "Peer #{n.id} down"}
    end
  end

  @spec notify(CNode.t(), CNode.t()) :: {:ok, String.t()} | {:error, String.t()}
  def notify(n, pred) do
    {resp, _} = HTTP.call(n.address, "notify", [pred, n.id])
    if resp == :ok do
      {:ok, "Peer #{n.id} notified"}
    else
      {:error, "Failed to notify #{n.id}"}
    end
  end

  @spec find_successor(CNode.t(), integer(), integer()) :: CNode.t() | {:error, String.t()}
  def find_successor(n, id, hops \\ 0) do
    {resp, msg} = HTTP.call(n.address, "find_successor", [id, n.id, hops])
    if resp == :ok do
      Utils.map2cnode(msg)
    else
#      IO.inspect(msg)
      {:error, "#{id} successor search failed at #{n.id}"}
    end
  end

  @spec predecessor(CNode.t()) :: CNode.t() | {:error, String.t()}
  def predecessor(n) do
    {resp, msg} = HTTP.call(n.address, "predecessor", [n.id])
    if resp == :ok do
      Utils.map2cnode(msg)
    else
      {:error, "predecessor search failed at #{n.id}"}
    end
  end

  @spec get(CNode.t(), String.t()) :: any() | {:error, String.t()}
  def get(n, key) do
    {resp, msg} = HTTP.call(n.address, "get", [key, n.id])
    if resp == :ok do
      msg
    else
      {:error, "Get operation from #{n.id} failed"}
    end
  end

  @spec put(CNode.t(), tuple) :: any() | {:error, String.t()}
  def put(n, record) do
    {resp, msg} = HTTP.call(n.address, "put", [record, n.id])
    if resp == :ok do
      msg
    else
      {:error, "Put operation to #{n.id} failed"}
    end
  end

  @spec notify_departure(CNode.t(), CNode.t(), CNode.t(), CNode.t()) :: {:ok, any()} | {:error, String.t()}
  def notify_departure(dest, n, pred, succ) do
    {resp, msg} = HTTP.call(dest.address, "notify_departure", [n, pred, succ, dest.id])
    if resp == :ok do
      {:ok, msg}
    else
      {:error, "Departure notification to #{dest.id} failed"}
    end
  end

end
