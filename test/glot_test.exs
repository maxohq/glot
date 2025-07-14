defmodule GlotTest do
  use ExUnit.Case
  doctest Glot

  test "greets the world" do
    assert Glot.hello() == :world
  end
end
