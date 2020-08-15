defmodule Transport.Server do
  @moduledoc false
  use JSONRPC2.Server.Handler
  import Utils, only: [map2cnode: 1, get_node_pid: 1]

  def handle_request("find_successor", [nd, destination_node, hops]) do
    get_node_pid(destination_node)
    |> GenServer.call({:find_successor, map2cnode(nd), hops})
  end

  def handle_request("notify", [chord_node, destination_node]) do
    get_node_pid(destination_node)
    |> GenServer.cast({:notify, map2cnode(chord_node)})

    "notified"
  end

  def handle_request("ping", [destination_node]) do
    get_node_pid(destination_node)
    |> case do
      nil -> "node down"
      _ -> "pong"
    end
  end

  def handle_request("predecessor", [destination_node]) do
    get_node_pid(destination_node)
    |> GenServer.call(:predecessor)
  end

  def handle_request("get", [key, destination_node]) do
    get_node_pid(destination_node)
    |> GenServer.call({:get, key})
  end

  def handle_request("put", [record, destination_node]) do
    get_node_pid(destination_node)
    |> GenServer.call({:put, record})
  end

  def handle_request("notify_departure", [n, pred, succ, destination_node]) do
    get_node_pid(destination_node)
    |> GenServer.cast({:notify_departure, n, pred, succ})
  end
end
