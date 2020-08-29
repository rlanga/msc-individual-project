defmodule TestSimulations do
  @moduledoc """
    Simulates Chord lookups against a network size given as an input argument
  """
  require Logger

  defp join_network(existing_node, nodes)
  defp join_network(_, []), do: :ok
  #  defp join_network(existing_node, [new_node | tail]) do
  #    Utils.get_node_pid(new_node)
  #    |> GenServer.call({:join, %CNode{id: existing_node}})
  #    join_network(new_node, tail)
  #  end
  defp join_network(nodes, [new_node | tail]) do
    existing_node = get_random_node_id(nodes, new_node)

    Utils.get_node_pid(new_node)
    |> GenServer.call({:join, %CNode{id: existing_node}})

    join_network(nodes, tail)
  end

  defp get_random_node_id(nodes, current \\ nil) do
    res = Enum.random(nodes)

    if res == current do
      get_random_node_id(nodes, current)
    else
      res
    end
  end

  defp bootstrap_network(size, interval_period) do
    Application.put_env(:chord, :simulation, true)
    Application.put_env(:chord, :network_size, size)
    Application.put_env(:chord, :fix_finger_interval, interval_period)
    Application.put_env(:chord, :predecessor_check_interval, interval_period)
    Application.put_env(:chord, :stabilization_interval, interval_period)
    Application.put_env(:chord, :trap_exit, false)
    node_ids = Enum.map(1..size, fn n -> Integer.to_string(n) |> Utils.generate_hash() end)
    Chord.start(:simulation)

    hd(node_ids)
    |> Utils.get_node_pid()
    |> GenServer.call(:create)

    join_network(node_ids, node_ids)
    node_ids
  end

  defp set_keys_into_network(node_ids, total \\ nil) do
    Logger.debug("...Setting keys into network...")
    number_of_keys = if total == nil, do: 100 * Enum.count(node_ids), else: total
    records = Enum.map(1..number_of_keys, fn n -> {Integer.to_string(n), 1} end)

    Enum.each(records, fn r ->
      get_random_node_id(node_ids)
      |> Utils.get_node_pid()
      |> GenServer.call({:put, r})
    end)

    records
  end

  defp perform_random_lookups(node_ids, keys) do
    Logger.debug("...Performing random lookups...")

    Task.async_stream(
      node_ids,
      fn n ->
        Enum.take_random(keys, 20)
        |> Enum.map(fn k ->
          Utils.get_node_pid(n) |> GenServer.call({:lookup, elem(k, 0)}) |> elem(1)
        end)
      end,
      ordered: false
    )
    |> Enum.map(fn {:ok, k} -> k end)
    |> List.flatten()

    #    |> Enum.frequencies()
  end

  defp run_path_length_simulation(%{} = args) do
    k = Map.get(args, :k, 3)
    stabilize_wait_time = Map.get(args, :stabilize_wait_time, 5)
    size = :math.pow(2, k) |> round()
    interval_period = Map.get(args, :interval, 5) * 1000

    #    Logger.configure_backend {LoggerFileBackend, :file_log}, path: "log/simulations/lookup_#{size}.log"
    ids = bootstrap_network(size, interval_period)
    Logger.debug("...Waiting for network to stabilise...")
    Process.sleep(stabilize_wait_time * 1000)
    keys = set_keys_into_network(ids, 100 * size)
    results = perform_random_lookups(ids, keys)
    Chord.stop([])
    results
  end

  @doc """
  This function is run in iex to test the path lengths of queries in the Chord network. \n
  Arguments for this function are:
    - k: the K value to start at
    - finish: the maximum K value to run tests against
  When run without arguments, it will run tests for network size 2^K in range 3 to 10
  """
  @spec test_path_length(integer(), integer()) :: :ok
  def test_path_length(k \\ 3, finish \\ 10)

  def test_path_length(k, finish) when k > finish do
    Logger.info("***path length simulation done***")
  end

  def test_path_length(k, finish) do
    output_dir = "lib/simulations/path_length_results.txt"
    File.touch(output_dir, System.os_time(:second))

    File.write(
      output_dir,
      {k,
       run_path_length_simulation(%{
         k: k,
         interval: 3,
         stabilize_wait_time: 40
       })}
      |> inspect(limit: :infinity)
      |> Kernel.<>("\n"),
      [:append]
    )

    test_path_length(k + 1, finish)
  end

  defp run_load_balance_simulation(%{} = args) do
    n = Map.get(args, :n, 4)
    stabilize_wait_time = Map.get(args, :stabilize_wait_time, 5)
    size = :math.pow(10, n) |> round
    total_keys = Map.get(args, :key_count, nil)
    interval_period = Map.get(args, :interval, 3) * 1000
    ids = bootstrap_network(size, interval_period)
    Logger.debug("...Waiting for network to stabilise...")
    Process.sleep(stabilize_wait_time * 1000)
    set_keys_into_network(ids, total_keys)
    keys = count_node_keys(ids)
    Chord.stop([])
    keys
  end

  @doc """
  This function is run in iex to test the load balance performance of the Chord network. \n
  Arguments for this function are:
    - key_count: the network key total to start the test with
    - max: the maximum network key total to run tests against
    - increment: the interval by which to increase the key_count in the next test iteration
  Without arguments, the function will run tests for total key counts in range 10^5 to 10^6 increasing by 10^5
  """
  @spec test_load_balance(integer(), integer(), integer()) :: :ok
  def test_load_balance(key_count \\ 100_000, max \\ 1_000_000, increment \\ 100_000)

  def test_load_balance(key_count, max, _) when key_count > max do
    Logger.info("***load balance simulation done***")
  end

  def test_load_balance(key_count, max, increment) do
    output_dir = "lib/simulations/load_balance_results.txt"
    File.touch(output_dir, System.os_time(:second))

    Enum.each(1..20, fn _ ->
      File.write(
        output_dir,
        {key_count,
         run_load_balance_simulation(%{
           key_count: key_count,
           interval: 3,
           stabilize_wait_time: 40
         })}
        |> inspect(limit: :infinity)
        |> Kernel.<>("\n"),
        [:append]
      )
    end)

    test_load_balance(key_count + increment, max, increment)
  end

  defp count_node_keys(node_ids) do
    Task.async_stream(node_ids, fn n ->
      Utils.get_node_pid(n) |> GenServer.call(:key_count)
    end)
    |> Enum.map(fn {:ok, k} -> k end)

    #    |> Enum.frequencies()
  end
end
