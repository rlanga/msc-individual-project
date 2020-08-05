defmodule LookupSimulation do
  @moduledoc """
    Simulates Chord lookups against a network size given as an input argument
  """
  require Logger

  defp join_network(existing_node, nodes)
  defp join_network(_, []), do: :ok
  defp join_network(existing_node, [new_node | tail]) do
    Utils.get_node_pid(new_node)
    |> GenServer.call({:join, %CNode{id: existing_node}})
    join_network(new_node, tail)
  end

  defp bootstrap_network(size, interval_period) do
    Application.put_env(:chord, :network_size, size)
    Application.put_env(:chord, :fix_finger_interval, interval_period)
    Application.put_env(:chord, :predecessor_check_interval, interval_period)
    Application.put_env(:chord, :stabilization_interval, interval_period)
    node_ids = Enum.map(1..size, fn n -> Integer.to_string(n)|> Utils.generate_hash() end)
    Chord.start(:normal)
    hd(node_ids)
    |> Utils.get_node_pid()
    |> GenServer.call(:create)

    join_network(hd(node_ids), tl(node_ids))
    node_ids
  end

  defp set_keys_into_network(node_ids) do
    number_of_keys = 100 * Enum.count(node_ids)
    records = Enum.map(1..number_of_keys, fn n -> {Integer.to_string(n), 1} end)
    Enum.each(records, fn r ->
      hd(node_ids)
      |> Utils.get_node_pid()
      |> GenServer.call({:put, r})
    end)
    records
  end

  defp perform_random_lookups(node_ids, keys) do
    Task.async_stream(node_ids, fn(n) ->
      Enum.take_random(keys, 50)
      |> Enum.each(fn k -> Utils.get_node_pid(n) |> GenServer.call({:lookup, elem(k, 0)}) end)
    end, ordered: false)
    |> Stream.run()
  end

  def run(args \\ %{}) do
    size = :math.pow(2, Map.get(args, :k, 3)) |> round()
    interval_period = Map.get(args, :interval, 5) * 1000
#    Logger.configure_backend {LoggerFileBackend, :file_log}, path: "log/simulations/lookup_#{size}.log"
    ids = bootstrap_network(size, interval_period)
    Logger.info("...Waiting for network to stabilise...")
    Process.sleep(20000)
    keys = set_keys_into_network(ids)
    perform_random_lookups(ids, keys)
  end
end