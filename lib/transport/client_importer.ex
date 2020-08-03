defmodule Transport.Client.Importer do
  @moduledoc false

  defmacro __using__(_) do
    if Application.get_env(:chord, :simulation, false) == true do
      quote do
        alias Transport.Simulation, as: RemoteNode
      end
    else
      quote do
        alias Transport.Client, as: RemoteNode
      end
    end
  end
end
