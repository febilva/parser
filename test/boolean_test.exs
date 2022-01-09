defmodule BooleanTest do
  use ExUnit.Case
  # doctest Boolean

  test "parse an integer" do
    assert Boolean.parse("1") == 1
  end
end
