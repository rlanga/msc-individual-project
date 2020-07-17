defmodule Chord do
  @moduledoc """
  Documentation for `Chord`.
  This is a proof-of-concept implementation of the Chord protocol using Elixir
  """
  use Application
  require Logger

  @impl true
  def start(_type, args \\ %{}) do
    server_port = if Map.has_key?(args, :port), do: args.port, else: Utils.generate_port_number()
    addr = if Map.has_key?(args, :address), do: args.address, else: "localhost:#{server_port}"
    nid = if Map.has_key?(args, :id), do: Utils.generate_hash(args.id), else: Utils.generate_hash(addr)

    cnode = %{id: Enum.random(1..10_000), start: {ChordNode, :start_link, [%{id: nid, addr: addr}]}}
    children = [JSONRPC2.Servers.HTTP.child_spec(:http, Transport.Server, [port: server_port]), cnode]
    sup_id = Supervisor.start_link(children, strategy: :one_for_one, name: Chord)
    Logger.info("Chord server started at http://localhost:#{server_port}")
    GenServer.call(String.to_atom("Node_#{nid}"), :create)

    if Map.has_key?(args, :join_id) and Map.has_key?(args, :join_address) do
      GenServer.call(String.to_atom("Node_#{nid}"), {:join, %CNode{id: args.join_id, address: args.join_address}})
    end
    sup_id
  end

  @doc """
  Set up a new Chord network.

  ## Examples

      iex> Chord.new(%{id: 1, addr: "localhost:4000"})
      {:ok}

  """
  def new(args) do
    # optional node id
    # address is mandatory
    # if address is not specified, use localhost
    # id must be a string
    nid = if Map.has_key?(args, :id) do
      args.id
    else
      args.addr
    end
    IO.puts(nid)
    {:ok}
  end

  @doc """
  Join an existing Chord network from an existing node
  """
  @spec join(integer(), integer(), String.t()) :: :ok
  def join(nid, id, address) do
    GenServer.call(String.to_atom("Node_#{nid}"), {:join, %CNode{id: id, address: address}})
  end

end
