defmodule ParserTest do
  use ExUnit.Case
  doctest Parser

  defp parse(input), do: input |> Parser.expr() |> unwrap
  defp unwrap({:ok, [acc], "", _, _, _}), do: acc
  defp unwrap({:ok, _, rest, _, _, _}), do: {:error, "could not parse" <> rest}
  defp unwrap({:error, reason, _rest, _, _, _}), do: {:error, reason}

  @err "expected boolean while processing !, " <>
         "followed by factor or (, followed by expr, followed by ) or boolean"

  test "parses consts" do
    assert true == parse("true")
    assert false == parse("false")
    assert {:error, @err} == parse("1")
  end

  test "parses negations" do
    assert {:!, [true]} == parse("!true")
    assert {:!, [false]} == parse("!false")
  end

  test "parses conjunctions" do
    assert {:&&, [{:!, [true]}, false]} == parse("!true&&false")
    assert {:!, [{:&&, [false, true]}]} == parse("!(false&&true)")
  end

  test "parses disjunctions" do
    assert {:||, [true, {:&&, [true, false]}]} == parse("true||true&&false")
    assert {:&&, [{:||, [true, true]}, false]} == parse("(true||true)&&false")
  end
end
