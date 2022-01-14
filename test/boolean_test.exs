defmodule BooleanTest do
  use ExUnit.Case
  # doctest Boolean

  test "parse a boolean" do
    assert Boolean.parse("true") == true
    assert Boolean.parse("false") == false
  end

  test "parse an integer" do
    assert Boolean.parse("1") == 1
    assert Boolean.parse("-1") == -1
  end

  @err "expected var while processing boolean or number or string or var"
  test "parse a float number" do
    assert Boolean.parse("1.0") == 1.0
    assert Boolean.parse("-1.0") === -1.0
    assert Boolean.parse("0.0001") === 0.0001
    assert {:error, @err, ".0001"} = Boolean.parse(".0001")
  end

  test "parse a variable" do
    assert Boolean.parse("a") == {:var, "a"}
    assert Boolean.parse("aAAA9_") == {:var, "aAAA9_"}
    assert Boolean.parse("aAAA9____") == {:var, "aAAA9____"}
    assert Boolean.parse("a-9") == {:error, "could not parse", "-9"}
    assert Boolean.parse("A") == {:error, @err, "A"}
    assert Boolean.parse("_A") == {:error, @err, "_A"}
    assert Boolean.parse("A_") == {:error, @err, "A_"}
  end

  describe "arithmetic expressions" do
    @err "expected var while processing " <>
           "(, followed by aexpr, followed by ) or number or var"

    test "return ok/error for consts" do
      assert Boolean.parse_aexpr("-1") == -1
      assert {:var, "test"} == Boolean.parse_aexpr("test")
    end

    test "return ok/error for addition/subtraction terms" do
      assert {:+, [1, 2]} == Boolean.parse_aexpr("1 +2")
      assert {:-, [1, -2]} == Boolean.parse_aexpr("1 --2")
      assert {:+, [1, {:+, [2, 3]}]} == Boolean.parse_aexpr("1+ (2+ 3)")
      assert {:error, @err, "!1+(2+3)"} == Boolean.parse_aexpr("!1+(2+3)")
    end

    test "obey math precedence rules" do
      for [input, ast] <- [
            [
              "1+1",
              {:+, [1, 1]}
            ],
            [
              "1 *2*3",
              {:*, [{:*, [1, 2]}, 3]}
            ],
            [
              "1+ 2 *3",
              {:+, [1, {:*, [2, 3]}]}
            ],
            [
              "( 1   +2 )  *3",
              {:*, [{:+, [1, 2]}, 3]}
            ],
            [
              "(-1 +2 - -1 *3)/4",
              {:/, [{:-, [{:+, [-1, 2]}, {:*, [-1, 3]}]}, 4]}
            ],
            [
              "(1)/ 2+ 2*(3)",
              {:+, [{:/, [1, 2]}, {:*, [2, 3]}]}
            ],
            [
              "( 1/2+ 2*3/ (myvar))",
              {:+, [{:/, [1, 2]}, {:/, [{:*, [2, 3]}, {:var, "myvar"}]}]}
            ]
          ] do
        assert ast == Boolean.parse_aexpr(input)
      end
    end
  end

  describe "boolean expressions" do
  end
end
