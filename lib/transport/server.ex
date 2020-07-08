defmodule Transport.Server do
  @moduledoc false
  use JSONRPC2.Server.Handler

  def handle_request("find_successor", [node_id, destination_node]) do
    IO.inspect("inserv #{destination_node}")
    GenServer.cast(String.to_atom("Node_#{destination_node}"), {:find_successor, node_id, self()})
    receive do
      {:res, val} -> val
    end
  end

  def handle_request("notify", [chord_node, destination_node]) do
    GenServer.call(String.to_atom("Node_#{destination_node}"), {:notify, chord_node})
    "notified"
  end

  def handle_request("ping", [destination_node]) do
    "pong"
  end

  def handle_request("predecessor", [destination_node]) do
    GenServer.call(String.to_atom("Node_#{destination_node}"), {:predecessor})
  end


end
