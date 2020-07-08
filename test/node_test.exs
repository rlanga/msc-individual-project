defmodule NodeTest do
  use ExUnit.Case, async: false

  defp start_node(port, id \\ "") do
#    t = JSONRPC2.Servers.HTTP.child_spec(:http, Transport.Server, [port: port])
#    t = %{t | id: Enum.random(1..10_000)}
#    start_supervised!(t)

    addr = "http://localhost:#{port}"
    nid = if id == "" do
      Chord.generate_hash(addr)
    else
       Chord.generate_hash(id)
    end
    spec = %{id: Enum.random(1..10_000), start: {ChordNode, :start_link, [%{id: nid, addr: addr}]}}
    {start_supervised!(spec), nid}
  end

  setup do
    start_supervised!(StateAgent)
    port = :rand.uniform(65535 - 1025) + 1025
    {nid, _} = start_node(port, "1")
    {_, tid} = JSONRPC2.Servers.HTTP.http(Transport.Server, [port: port, ref: "HTTP_#{port}"])
    GenServer.call(nid, :create)
    on_exit(fn ->
            ref = Process.monitor(tid)

            JSONRPC2.Servers.HTTP.shutdown("HTTP_#{port}")

            receive do
              {:DOWN, ^ref, :process, ^tid, :shutdown} -> :ok
            end
    end)
    %{node: nid, node_details: %CNode{id: Chord.generate_hash("1"), address: "http://localhost:#{port}"}, port: port}
  end

  @moduletag :capture_log

  doctest ChordNode

  test "module exists" do
    assert is_list(ChordNode.module_info())
  end

#
#  test "number is not in closed interval" do
#    assert ChordNode.in_closed_interval?(1, 1, 3) == false
#  end


#  test "new network is created", %{node: pid} do
#    assert GenServer.call(pid, :create) == :ok
##    stop_supervised(pid)
#  end

  test "notifying other node works", %{node_details: cnode, port: port} do
    {new_node, _} = start_node(port, "2")
    assert GenServer.call(new_node, {:notify, cnode}) == :ok
  end

#  test "predecessor check works", %{node: pid} do
#    assert GenServer.in(pid, :check_predecessor) == :ok
#  end

  test "node joins network", %{node_details: cnode, port: port} do
    {new_node, _} = start_node(port, "2")
     assert GenServer.call(new_node, {:join, cnode}) == :ok
  end

  test "node successor is itself", %{node: pid, node_details: cnode} do
    GenServer.cast(pid, {:find_successor, cnode.id, self()})
    receive do
      {:res, val} -> assert val == cnode
    end
  end

  test "node successor is itself if it\'s ID larger than other node", %{node: pid, node_details: cnode, port: port} do
    {new_node, nid} = start_node(port, "2")
    GenServer.cast(new_node, {:find_successor, nid, self()})
    receive do
      {:res, val} -> assert val == %CNode{id: nid, address: cnode.address}
    end
  end
end
