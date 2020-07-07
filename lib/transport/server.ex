defmodule Transport.Server do
  @moduledoc false
  use JSONRPC2.Server.Handler

  def handle_request("find_successor", [node_id]) do
    IO.inspect("inserv")
    GenServer.call(StateAgent.get(:chord_node_ref), {:find_successor, node_id}, 10_000)
  end

  def handle_request("notify", [chord_node]) do
    GenServer.call(StateAgent.get(:chord_node_ref), {:notify, chord_node})
    "notified"
  end

  def handle_request("ping", []) do
    "pong"
  end

  def handle_request("predecessor", []) do
    GenServer.call(StateAgent.get(:chord_node_ref), {:predecessor})
  end


end
