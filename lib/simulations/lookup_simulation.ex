defmodule LookupSimulation do
  @moduledoc """
    Simulates Chord lookups against a network size given as an input argument
  """

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
  end

  def run(args \\ %{}) do
    size = Map.get(args, :size, 32)
    interval_period = Map.get(args, :interval, 30) * 1000
#    Logger.configure_backend {LoggerFileBackend, :file_log}, path: "log/simulations/lookup_#{size}.log"
    bootstrap_network(size, interval_period)
  end
end