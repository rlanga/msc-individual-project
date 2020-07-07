defmodule StateAgent do
  use Agent
  @moduledoc """
  Stores shared state for items like server references
  """

  def start_link(initial_value) do
    initial_value = if initial_value == [] do %{} else initial_value end
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def get(key) do
    Agent.get(__MODULE__, &Map.get(&1, key))
  end

  def put(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end

end
