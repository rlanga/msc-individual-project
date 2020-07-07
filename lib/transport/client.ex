defmodule Transport.Client do
  @moduledoc false
  alias JSONRPC2.Clients.HTTP

  @spec ping(CNode.t()) :: {:ok, String.t()} | {:error, String.t()}
  def ping(n) do
    {resp, _} = HTTP.call(n.address, "ping", [])
    if resp == :ok do
      {:ok, "Peer #{n.id} still up"}
    else
      {:error, "Peer #{n.id} down"}
    end
  end

  @spec notify(CNode.t()) :: {:ok, String.t()} | {:error, String.t()}
  def notify(n) do
    {resp, _} = HTTP.call(n.address, "notify", [])
    if resp == :ok do
      {:ok, "Peer #{n.id} notified"}
    else
      {:error, "Failed to notify #{n.id}"}
    end
  end

  @spec find_successor(CNode.t(), integer) :: {:ok, CNode.t()} | {:error, String.t()}
  def find_successor(n, id) do
    {resp, msg} = HTTP.call(n.address, "find_successor", [id])
    if resp == :ok do
      {:ok, msg}
    else
      IO.inspect(msg)
      {:error, "#{id} successor search failed at #{n.id}"}
    end
  end

  @spec predecessor(CNode.t()) :: {:ok, CNode.t()} | {:error, String.t()}
  def predecessor(n) do
    {resp, msg} = HTTP.call(n.address, "predecessor", [])
    if resp == :ok do
      {:ok, msg}
    else
      {:error, "predecessor search failed at #{n.id}"}
    end
  end

end
