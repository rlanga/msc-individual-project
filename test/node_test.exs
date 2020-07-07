defmodule NodeTest do
  use ExUnit.Case, async: false

  defp start_node(port, id \\ "") do
#    t = JSONRPC2.Servers.HTTP.child_spec(:http, Transport.Server, [port: port])
#    t = %{t | id: Enum.random(1..10_000)}
#    start_supervised!(t)
    {_, sid} = JSONRPC2.Servers.HTTP.http(Transport.Server, port: port)

    addr = "http://localhost:#{port}"
    spec = if id == "" do
      %{id: Enum.random(1..10_000), start: {ChordNode, :start_link, [%{addr: addr}]}}
    else
      %{id: Enum.random(1..10_000), start: {ChordNode, :start_link, [%{id: id, addr: addr}]}}
    end
    {start_supervised!(spec), sid}
  end

  setup do
#    spec = %{id: Enum.random(1..10_000), start: {ChordNode, :start_link, [%{addr: "http://localhost:4000"}]}}
    start_supervised!(StateAgent)
    {nid, tid} = start_node(4000, "1")
    GenServer.call(nid, :create)
    on_exit(fn ->
            ref = Process.monitor(tid)

            JSONRPC2.Servers.HTTP.shutdown(Transport.Server.HTTP)

            receive do
              {:DOWN, ^ref, :process, ^tid, :shutdown} -> :ok
            end
    end)
    %{node: nid, node_details: %CNode{id: ChordNode.generate_hash("1"), address: "http://localhost:4000"}}
  end

  @moduletag :capture_log

  doctest ChordNode

  test "module exists" do
    assert is_list(ChordNode.module_info())
  end

#  test "closed interval check works" do
#    assert ChordNode.in_closed_interval?(2, 1, 3) == true
#  end
#
#  test "number is not in closed interval" do
#    assert ChordNode.in_closed_interval?(1, 1, 3) == false
#  end


#  test "new network is created", %{node: pid} do
#    assert GenServer.call(pid, :create) == :ok
##    stop_supervised(pid)
#  end

  test "notifying other node works", %{node_details: cnode} do
    {new_node, _} = start_node(4001)
    assert GenServer.call(new_node, {:notify, cnode}) == :ok
  end

#  test "predecessor check works", %{node: pid} do
#    assert GenServer.in(pid, :check_predecessor) == :ok
#  end

  test "node joins network", %{node_details: cnode} do
    {new_node, _} = start_node(4001, "2")
#    IO.inspect(m)
#    GenServer.call(pid, {:find_successor, 33242}) |> IO.inspect
    assert GenServer.call(new_node, {:join, cnode}, 10_000) == :ok
  end
end
