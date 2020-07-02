defmodule NodeState do
  @moduledoc false
  defstruct id: nil,
            predecessor: nil,
            successor: nil,
            finger: [],
            keys: [],
            stabilization_interval: 30 * 1000,
            bit_size: nil
end
