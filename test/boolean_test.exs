defmodule BooleanTest do
  use ExUnit.Case
  # doctest Boolean

  test "parse an integer" do
    assert Boolean.parse("1") == 1
    assert Boolean.parse("-1") == -1
  end

  @err "expected digits while processing integer inside number"
  test "parse a float number" do
    assert Boolean.parse("1.0") == 1.0
    assert Boolean.parse("-1.0") === -1.0
    assert Boolean.parse("0.0001") === 0.0001
    assert {:error, @err, ".0001"} = Boolean.parse(".0001")
  end

  test "parse a variable" do
    assert Boolean.parse("a") == {:var, "a"}
  end
end
