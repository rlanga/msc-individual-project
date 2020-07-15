defmodule Chord do
  @moduledoc """
  Documentation for `Chord`.
  This is a proof-of-concept implementation of the Chord protocol using Elixir
  """

  @doc """
  Set up a new Chord network.

  ## Examples

      iex> Chord.new(%{id: 1, addr: "localhost:4000"})
      {:ok}

  """
  def new(args) do
    # optional node id
    # address is mandatory
    # if address is not specified, use localhost
    # id must be a string
    nid = if Map.has_key?(args, :id) do
      args.id
    else
      args.addr
    end
    {:ok}
  end

  @doc """
  Join an existing Chord network from an existing node
  """
  def join(address) do

  end

end
