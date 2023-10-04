defmodule DieselTest do
  use ExUnit.Case
  doctest Diesel

  test "greets the world" do
    assert Diesel.hello() == :world
  end
end
