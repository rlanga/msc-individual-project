defmodule Storage do
  import Utils
  @moduledoc """
  Wrapper functions to interact with the ETS storage layer of a node.
  """

  @type node_table :: pid()
  @type record :: tuple() | [tuple()]
  @type key :: String.t()

  @doc """
  Initialise the node's storage layer
  """
  @spec init(atom()) :: reference()
  def init(node_name) do
    :ets.new(node_name, [:ordered_set, :private])
  end

  @spec get(node_table, key) :: any() | nil
  def get(table, key) do
    case :ets.lookup(table, key) do
      [res] -> elem(res, 1)
      _ -> nil
    end
  end

  @doc """
  Get all records from the storage table
  """
  @spec get_all(node_table) :: record
  def get_all(table) do
    :ets.tab2list(table)
  end

  @doc """
  Add a record or a list of records into the storage table
  """
  @spec put(node_table, record) :: true
  def put(table, record) do
    :ets.insert(table, record)
  end

  @spec delete(node_table, key) :: true
  def delete(table, key) do
    :ets.delete(table, key)
  end

  @doc """
  Gets records that fall within a hashed key range
  """
  @spec get_record_range(node_table, key, key) :: record
  def get_record_range(table, from, to) do
    :ets.foldl(fn({key, obj}, acc) when in_half_closed_interval?(generate_hash(key), from, to) -> [{key, obj} | acc]
                                                                                        (_, acc) -> acc
    end, [], table)
  end

  @doc """
  Deletes multiple records after the keys have been transferred
  """
  @spec delete_record_range(node_table, [key]) :: :ok
  def delete_record_range(table, keys) do
    Enum.each(keys, fn k -> :ets.delete(table, k) end)
  end

#  @spec in_range?(record, list) :: list
#  defp in_range?(record, acc) do
#    hKey = generate_hash(elem(record, 0))
#    case in_half_closed_interval?() do
#       -> 1
#    end
#  end
end
