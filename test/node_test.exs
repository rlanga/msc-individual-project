defmodule NodeTest do
  use ExUnit.Case

  setup do
    start_supervised!(ChordNode)
    %{node: node}
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

#  test "node create call works", %{node, node} do
#    assert ChordNode.create()
#  end

  test "closest preceding finger is found" do
    ChordNode.closest_preceding_finger()
  end
end
