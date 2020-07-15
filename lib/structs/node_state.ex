defmodule NodeState do
  @moduledoc false
  defstruct node: nil,
            predecessor: nil,
            successor: nil,
            finger: %{1 => nil},
            keys: [],
            storage_ref: nil,
            stabilization_interval: 30 * 1000, # 30 seconds
            finger_fix_interval: 30 * 1000, # 30 seconds
            predecessor_check_interval: 30 * 1000, # 30 seconds
            bit_size: 160, # Default is 160 bits as that's the size of SHA-1
            next_fix_finger: 0
end
