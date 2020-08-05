defmodule Utils do
  @moduledoc """
  Utility functions shared across the application modules
  """

  @doc """
  Generates a 160-bit integer SHA-1 hash of the input data
  """
  @spec generate_hash(String.t()) :: integer()
  def generate_hash(data) do
    :crypto.hash(:sha, data)
    |> Base.encode16
    |> Integer.parse(16)
    |> elem(0)
  end

  @doc """
  Checks a value is in a half-closed interval (a,b]
  """
  @spec in_half_closed_interval?(integer, integer, integer) :: boolean()
  def in_half_closed_interval?(val, a, b) do
    val > a and val <= b
  end

  @doc """
  Checks a value is in a closed interval (a,b)
  """
  @spec in_closed_interval?(integer, integer, integer) :: boolean()
  def in_closed_interval?(val, a, b) do
    val > a and val < b
  end

  @doc """
  Generates a random port number
  """
  @spec generate_port_number() :: integer()
  def generate_port_number() do
    :rand.uniform(65535 - 1025) + 1025
  end

  @doc """
  Converts a map object to a CNode struct
  """
  @spec map2cnode(map()) :: CNode.t()
  def map2cnode(n) do
    if is_struct(n) do
      n
    else
      %CNode{id: n["id"], address: n["address"]}
    end
  end

  @spec id_to_cnode(integer()) :: CNode.t()
  def id_to_cnode(id) do
    %CNode{id: id, address: nil}
  end

  @doc """
  Searches the process registry for a node's PID
  """
  @spec get_node_pid(integer()) :: pid() | nil
  def get_node_pid(id) do
    String.to_atom("Node_#{id}")
    |> GenServer.whereis
  end

end
