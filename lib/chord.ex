defmodule Chord do
  @moduledoc """
  Documentation for `Chord`.
  This is a proof-of-concept implementation of the Chord protocol using Elixir
  """
  use Application
  require Logger
  require Utils

  @impl true
  def start(_type, args \\ %{}) do
    if is_simulation?() do
      start_simulation_mode()
    else
      start_normal_mode()
    end
  end

  defp start_normal_mode() do
    #    server_port = if Map.has_key?(args, :port), do: args.port, else: Utils.generate_port_number()
    #    addr = if Map.has_key?(args, :address), do: args.address, else: "localhost:#{server_port}"
    #    node_id = if Map.has_key?(args, :id), do: Utils.generate_hash(args.id), else: Utils.generate_hash(addr)
    server_port = get_port_from_config()
    addr = case get_address_from_config() do
      nil ->
        "localhost:#{server_port}"
      val ->
        val
    end
    node_id = case get_node_id_from_config() do
      nil ->
        Utils.generate_hash(addr)
      id ->
        id
    end

    node_spec = %{id: Enum.random(1..10_000), start: {ChordNode, :start_link, [%{id: node_id, addr: addr}]}}
    agent_spec = {StateAgent, %{node_ref: String.to_atom("Node_#{node_id}")}}
    children = [JSONRPC2.Servers.HTTP.child_spec(:http, Transport.Server, [port: server_port]), node_spec, agent_spec]
    supervisor_id = Supervisor.start_link(children, strategy: :one_for_one, name: Chord)
    Logger.info("Chord server started at #{addr}")
    GenServer.call(String.to_atom("Node_#{node_id}"), :create)

    join_id = Application.get_env(:chord, :join_id)
    join_address = Application.get_env(:chord, :join_address)
    if join_id != nil and join_address != nil do
      GenServer.call(String.to_atom("Node_#{node_id}"), {:join, %CNode{id: join_id, address: join_address}})
    end
    supervisor_id
  end

  defp start_simulation_mode() do
    network_size = get_network_size_from_config()
    nodes = Enum.map(1..network_size, fn n ->
      %{id: n, start: {ChordNode, :start_link, [%{id: Utils.generate_hash(n), addr: nil}]}}
    end)

    supervisor_id = Supervisor.start_link(nodes, strategy: :one_for_one, name: Chord)
    Logger.info("Chord simulator started")
    supervisor_id
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

  @doc """
  Yields the IP address of the node responsible for the key
  """
  @spec lookup(String.t()) :: String.t() | {:error, String.t()}
  def lookup(key) do
    StateAgent.get(:node_ref)
    |> GenServer.call({:find_successor, Utils.generate_hash(key)})
  end

  defp get_config_value(key) do
    Application.fetch_env(:chord, key)
  end

  defp get_address_from_config() do
    get_config_value(:address)
    |> case do
         {:ok, val} ->
           val
         :error ->
           nil
       end
  end

  defp get_port_from_config() do
    get_config_value(:port)
    |> case do
         {:ok, val} ->
           val
         :error ->
           Utils.generate_port_number()
       end
  end

  defp get_node_id_from_config() do
    get_config_value(:id)
    |> case do
         {:ok, val} ->
           val
         :error ->
           nil
       end
  end

  defp get_network_size_from_config() do
    get_config_value(:simulation_network_size)
    |> case do
         {:ok, val} ->
           val
         :error ->
           32
       end
  end

  defp is_simulation?() do
    get_config_value(:simulation)
    |> case do
         {:ok, val} ->
           val
         :error ->
           false
       end
  end

end
