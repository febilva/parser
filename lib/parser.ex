defmodule Parser do
  @moduledoc """
  Sample parser for article on:
  http://stefan.lapers.be/posts/elixir-writing-an-expression-parser-with-nimble-parsec/
  """
  import NimbleParsec

  not_ = string("!") |> label("!")
  and_ = string("&&") |> replace(:&&) |> label("&&")
  or_ = string("||") |> replace(:||) |> label("||")
  lparen = ascii_char([?(]) |> label("(")
  rparen = ascii_char([?)]) |> label(")")

  # <const> :== "true" | "false"
  true_ = string("true") |> replace(true) |> label("true")
  false_ = string("false") |> replace(false) |> label("false")
  const = choice([true_, false_]) |> label("boolean")

  # <factor> :== <not> <expr> | "(" <expr> ")" | <const>
  negation = not_ |> ignore |> parsec(:factor) |> tag(:!)
  grouping = ignore(lparen) |> parsec(:expr) |> ignore(rparen)
  defcombinatorp(:factor, choice([negation, grouping, const]))

  # <term> :== <factor> {<and> <factor>}
  defcombinatorp(
    :term,
    parsec(:factor)
    |> repeat(and_ |> parsec(:factor))
    |> reduce(:fold_infixl)
  )

  # <expr> :== <term> {<or> <term>}
  defparsec(
    :expr,
    parsec(:term)
    |> repeat(or_ |> parsec(:term))
    |> reduce(:fold_infixl)
  )

  defp fold_infixl(acc) do
    acc
    |> Enum.reverse()
    |> Enum.chunk_every(2)
    |> List.foldr([], fn
      [l], [] -> l
      [r, op], l -> {op, [l, r]}
    end)
  end
end
