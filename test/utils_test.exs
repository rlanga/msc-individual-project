defmodule UtilsTest do
  use ExUnit.Case

  alias Utils

  @moduletag :capture_log

  doctest Utils

  test "module exists" do
    assert is_list(Utils.module_info())
  end

  test "number is at start of half-closed interval" do
    assert Utils.in_half_closed_interval?(1, 1, 3) == false
  end

  test "number is in half-closed interval" do
    assert Utils.in_half_closed_interval?(2, 1, 3) == true
  end

  test "number is at end of half-closed interval" do
    assert Utils.in_half_closed_interval?(3, 1, 3) == true
  end

  test "number is not in closed interval" do
    assert Utils.in_closed_interval?(1, 1, 3) == false
  end
end
