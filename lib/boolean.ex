defmodule Boolean do
  import NimbleParsec

  digits = [?0..?9] |> ascii_string(min: 1) |> label("digits")

  float =
    optional(string("-"))
    |> concat(digits)
    |> ascii_string([?.], 1)
    |> concat(digits)
    |> reduce(:to_float)
    |> label("float")

  int =
    optional(string("-"))
    |> concat(digits)
    |> reduce(:to_integer)
    |> label("integer")

  defp to_float(acc), do: acc |> Enum.join() |> String.to_float()
  defp to_integer(acc), do: acc |> Enum.join() |> String.to_integer(10)

  var = ascii_char([?a..?z]) |> repeat(ascii_char([?a..?z])) |> label("var")
  num = choice([float, int]) |> label("number")

  defparsec(
    :parse_string,
    choice([var, num])
  )

  def parse(string) do
    parse_string(string)
    |> unwrap
  end

  defp unwrap({:ok, [acc], "", _, _, _}), do: acc
  defp unwrap({:ok, _, rest, _, _, _}), do: {:error, "could not parse", rest}
  defp unwrap({:error, reason, rest, _, _, _}), do: {:error, reason, rest}
end
