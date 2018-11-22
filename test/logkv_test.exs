defmodule LogKVTest do
  use ExUnit.Case
  doctest LogKV

  test "greets the world" do
    assert LogKV.hello() == :world
  end
end
