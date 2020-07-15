defmodule Utils do
  @moduledoc """
  Utility functions shared across the application modules
  """

  @doc """
  Generates a 160-bit integer SHA-1 hash of the input data
  """
  @spec generate_hash(any()) :: integer
  def generate_hash(data) do
    :crypto.hash(:sha, data)
    |> Base.encode16
    |> Integer.parse(16)
    |> elem(0)
  end

  @doc """
  Checks a value is in a half-closed interval (a,b]
  """
  @spec in_half_closed_interval?(integer, integer, integer) :: true | false
  def in_half_closed_interval?(val, a, b) do
    in_closed_interval?(val, a, b) and val <= b
  end

  @doc """
  Checks a value is in a closed interval (a,b)
  """
  @spec in_closed_interval?(integer, integer, integer) :: true | false
  def in_closed_interval?(val, a, b) do
    val > a and val < b
  end

end
