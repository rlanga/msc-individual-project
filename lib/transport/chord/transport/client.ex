defmodule Chord.Transport.Client do
  @moduledoc false
  alias JSONRPC2.Clients.HTTP

  @spec ping(CNode) :: {:ok, String.t()} | {:error, String.t()}
  def ping(node) do
    {resp, _} = HTTP.call(node.address, "ping", [])
    if resp == :ok do
      {:ok, "Peer #{node.id} still up"}
    else
      {:error, "Peer #{node.id} down"}
    end
  end

  @spec notify(CNode) :: {:ok, String.t()} | {:error, String.t()}
  def notify(node) do
    {resp, _} = HTTP.call(node.address, "notify", [])
    if resp == :ok do
      {:ok, "Peer #{node.id} notified"}
    else
      {:error, "Failed to notify #{node.id}"}
    end
  end

  @spec find_successor(CNode) :: {:ok, CNode} | {:error, String.t()}
  def find_successor(node, id) do
    {resp, msg} = HTTP.call(node.address, "find_successor", [id])
    if resp == :ok do
      {:ok, msg}
    else
      {:error, "#{id} successor search failed at #{node.id}"}
    end
  end

  def find_predecessor(CNode) do

  end

end
