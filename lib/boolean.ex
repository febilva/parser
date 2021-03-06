defmodule Boolean do
  import NimbleParsec

  @reserved_sym ["true", "false"]

  true_ = string("true") |> replace(true)
  false_ = string("false") |> replace(false)

  boolean = [true_, false_] |> choice |> label("boolean")

  digits = [?0..?9] |> ascii_string(min: 1) |> label("digits")

  float =
    optional(string("-"))
    |> concat(digits)
    |> ascii_string([?.], 1)
    |> concat(digits)
    |> reduce(:to_float)
    |> label("float")

  defp to_float(acc), do: acc |> Enum.join() |> String.to_float()

  int =
    optional(string("-"))
    |> concat(digits)
    |> reduce(:to_integer)
    |> label("integer")

  defp to_integer(acc), do: acc |> Enum.join() |> String.to_integer(10)

  num = choice([float, int]) |> label("number")

  var =
    ascii_char([?a..?z])
    |> repeat(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_]))
    |> post_traverse(:to_varname)
    |> unwrap_and_tag(:var)
    |> label("var")

  defp to_varname(_rest, acc, context, _line, _offset) do
    name = acc |> Enum.reverse() |> List.to_string()

    if name in @reserved_sym do
      {:error, name <> " is a reserved symbol"}
    else
      {[name], context}
    end
  end

  string =
    ignore(ascii_char([?"]))
    |> repeat_while(
      utf8_char([]),
      {:not_quote, []}
    )
    |> ignore(ascii_char([?"]))
    |> reduce({List, :to_string, []})
    |> label("string")

  defp not_quote(<<?", _::binary>>, context, _, _), do: {:halt, context}
  defp not_quote(_, context, _, _), do: {:cont, context}

  defparsec(
    :parse_string,
    [boolean, num, string, var]
    |> choice
  )

  plus = ascii_char([?+]) |> replace(:+) |> label("+")
  minus = ascii_char([?-]) |> replace(:-) |> label("-")
  times = ascii_char([?*]) |> replace(:*) |> label("*")
  divide = ascii_char([?/]) |> replace(:/) |> label("/")
  lparen = ascii_char([?(]) |> label("(")
  rparen = ascii_char([?)]) |> label(")")
  whitespace = ascii_char([?\s, ?\t]) |> times(min: 1)

  ignore_surrounding_whitespace = fn p ->
    ignore(optional(whitespace))
    |> concat(p)
    |> ignore(optional(whitespace))
  end

  defcombinatorp(
    :aexpr_factor,
    [
      ignore(lparen) |> parsec(:aexpr) |> ignore(rparen),
      num,
      var
    ]
    |> choice()
    |> ignore_surrounding_whitespace.()
  )

  defparsecp(
    :aexpr_term,
    parsec(:aexpr_factor)
    |> repeat([times, divide] |> choice() |> parsec(:aexpr_factor))
    |> reduce(:fold_infixl)
  )

  defparsec(
    :aexpr,
    parsec(:aexpr_term)
    |> repeat([plus, minus] |> choice() |> parsec(:aexpr_term))
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

  def parse(string) do
    parse_string(string)
    |> unwrap
  end

  def parse_aexpr(string) do
    aexpr(string) |> unwrap()
  end

  defp unwrap({:ok, [acc], "", _, _, _}), do: acc
  defp unwrap({:ok, _, rest, _, _, _}), do: {:error, "could not parse", rest}
  defp unwrap({:error, reason, rest, _, _, _}), do: {:error, reason, rest}
end
