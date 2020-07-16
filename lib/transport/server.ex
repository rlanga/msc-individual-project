defmodule Transport.Server do
  @moduledoc false
  use JSONRPC2.Server.Handler

  def handle_request("find_successor", [nd, destination_node]) do
#    IO.inspect("inserv #{destination_node}")
    GenServer.call(String.to_atom("Node_#{destination_node}"), {:find_successor, %CNode{id: nd["id"], address: nd["address"]}})
  end

  def handle_request("notify", [chord_node, destination_node]) do
    GenServer.cast(String.to_atom("Node_#{destination_node}"), {:notify, %CNode{id: chord_node["id"], address: chord_node["address"]}})
    "notified"
  end

  def handle_request("ping", [destination_node]) do
    case GenServer.whereis(String.to_atom("Node_#{destination_node}")) do
      nil -> "node down"
      _ -> "pong"
    end
  end

  def handle_request("predecessor", [destination_node]) do
    GenServer.call(String.to_atom("Node_#{destination_node}"), {:predecessor})
  end

  def handle_request("get", [key, destination_node]) do
    GenServer.call(String.to_atom("Node_#{destination_node}"), {:get, key})
  end

  def handle_request("put", [record, destination_node]) do
    GenServer.call(String.to_atom("Node_#{destination_node}"), {:put, record})
  end

  def handle_request("notify_departure", [n, pred, succ, destination_node]) do
    GenServer.cast(String.to_atom("Node_#{destination_node}"), {:notify_departure, n, pred, succ})
  end
end
