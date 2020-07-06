defmodule Chord.Transport.Server do
  @moduledoc false
  use JSONRPC2.Server.Handler

  def handle_request("find_successor", [id]) do

  end

  def handle_request("notify", [chordNode]) do
    "notified"
  end

  def handle_request("ping", []) do
    "pong"
  end


end
