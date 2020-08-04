#! /usr/bin/env elixir
# lookup_simulation.ex

defmodule LookupSimulation do
  @moduledoc """
  synopsis:
    Simulates Chord lookups against a network size given as an input argument
  usage:
    $ lookup_simulation {options} size
  """

  def join_network(existing_node, nodes)
  def join_network(_, []), do: :ok
  def join_network(existing_node, [new_node | tail]) do
    Utils.get_node_pid(new_node)
    |> GenServer.call({:join, existing_node})
    join_network(new_node, tail)
  end

  def bootstrap_network(size) do
    Application.put_env(:chord, :network_size, size)
    node_ids = Enum.map(1..size, fn n -> Integer.to_string(n)|> Utils.generate_hash() end)
    Chord.start(:normal)
    hd(node_ids)
    |> Utils.get_node_pid()
    |> GenServer.call(:create)

    join_network(hd(node_ids), node_ids)
  end

  def main([help_opt]) when help_opt == "-h" or help_opt == "--help" do
    IO.puts(@moduledoc)
  end
  def main(args) do
    {_, cmd_and_args, errors} = parse_args(args)
    case errors do
      [] ->
        size = if Enum.count(cmd_and_args) > 0, do: String.to_integer(hd(cmd_and_args), 10), else: 32
        bootstrap_network(size)
      _ ->
        IO.puts("Bad option:")
        IO.inspect(errors)
        IO.puts(@moduledoc)
    end
  end

  # Code applied from: http://davekuhlman.org/elixir-escript-mix.html
  defp parse_args(args) do
    {opts, cmd_and_args, errors} =
      args
      |> OptionParser.parse(strict:
        [help: :boolean])
    {opts, cmd_and_args, errors}
  end

#  defp process_args(opts, args) do
#    count = Keyword.get(opts, :count, 1)
#    convertfn = if Keyword.has_key?(opts, :upcase) do
#      fn (arg) -> String.upcase(arg) end
#    else
#      fn (arg) -> arg end
#    end
#    Stream.iterate(0, &(&1 + 1))
#    |> Stream.take(count)
#    |> Enum.each(fn (idx) ->
#      if idx > 0 do
#        IO.puts("-----------------")
#      end
#      Stream.with_index(args)
#      |> Enum.each(fn ({arg, index}) ->
#        arg1 = convertfn.(arg)
#        IO.puts("arg #{index + 1}. #{arg1}") end)
#    end)
#  end
end

LookupSimulation.main(System.argv())