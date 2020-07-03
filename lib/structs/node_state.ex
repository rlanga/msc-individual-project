defmodule NodeState do
  @moduledoc false
  defstruct node: nil,
            predecessor: nil,
            successor: nil,
            finger: [],
            keys: [],
            stabilization_interval: 30 * 1000, # 30 seconds
            bit_size: 160 # Default is 160 bits as that's the size of SHA-1
end
