defmodule Chord.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(nodes) do
    Supervisor.start_link(__MODULE__, nodes, name: __MODULE__)
  end

  def init(nodes) do
    Supervisor.init(nodes, strategy: :one_for_one)
  end

  def kill_node(id) do
    String.to_atom("Node_#{id}")
    |> GenServer.stop({:shutdown, :ungraceful})
  end

  def start_node(id) do
    Supervisor.start_child(__MODULE__, 1)
  end
end
