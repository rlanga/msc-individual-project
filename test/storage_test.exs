defmodule StorageTest do
  use ExUnit.Case
  import Utils, only: [generate_hash: 1]

  alias Storage

  @moduletag :capture_log

  doctest Storage

  setup do
    %{table: Storage.init(:test)}
  end

  test "module exists" do
    assert is_list(Storage.module_info())
  end

  test "get value works", %{table: table} do
    Storage.put(table, {"key", "value"})
    assert Storage.get(table, "key") == "value"
  end

  test "inserting multiple values at once works", %{table: table} do
    Storage.put(table, [{"key", "value"}, {"key2", "value2"}])
    assert Storage.get(table, "key") == "value"
  end

  test "get all works", %{table: table} do
    values = [{"key", "value"}, {"key2", "value2"}]
    Storage.put(table, values)
    assert Storage.get_all(table) == values
  end

  test "get record range works", %{table: table} do
    values = [{"3", "value"}, {"5", "value2"}]
    Storage.put(table, values)

    assert Storage.get_record_key_range(table, generate_hash("1"), generate_hash("5")) ==
             Enum.reverse(values)
  end
end
