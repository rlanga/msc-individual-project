defmodule ChordTest do
  use ExUnit.Case
  doctest Chord

  @tag :pending
  test "creates new Chord network" do
    assert Chord.new() == {:ok}
  end
end
