defmodule CNode do
  @moduledoc """
  Struct for a Chord Node {id, address} mapping.
  It has been named CNode to avoid clash with the system 'Node' keyword
  """
  defstruct id: "", address: nil
end
