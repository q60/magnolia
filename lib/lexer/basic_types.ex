defmodule Lexer.BasicTypes do
  def add_string(chars, string \\ "")
  def add_string([], string), do: {String.length(string) + 2, :err}

  def add_string([char | next], string) do
    case char do
      "\"" ->
        {String.length(string) + 2, Token.add(:STRING, string)}

      _ ->
        add_string(next, string <> char)
    end
  end

  def add_number([char | next], base, number \\ "") do
    decimal_points = (String.graphemes(number) |> Enum.frequencies())["."]

    cond do
      Regex.match?(~r/[\d\.]/, char) ->
        add_number(next, base, number <> char)

      decimal_points != nil && decimal_points > 1 ->
        {String.length(number), :err}

      decimal_points != nil && decimal_points == 1 ->
        {float, _} = Float.parse(number)
        {String.length(number), Token.add(:NUMBER, float)}

      true ->
        {integer, _} = Integer.parse(number, base)
        {String.length(number), Token.add(:NUMBER, integer)}
    end
  end

  def add_identifier([char | next], token \\ "") do
    cond do
      Regex.match?(~r/[a-zA-Z\.\d_@]/, char) ->
        add_identifier(next, token <> char)

      true ->
        type =
          case token do
            "and" -> :AND
            "or" -> :OR
            "not" -> :NOT
            "if" -> :IF
            "while" -> :WHILE
            "for" -> :FOR
            "true" -> :TRUE
            "false" -> :FALSE
            "print" -> :PRINT
            "call" -> :CALL
            "clear" -> :CLEAR
            "drop" -> :DROP
            "swap" -> :SWAP
            "dup" -> :DUP
            "over" -> :OVER
            "rep" -> :REP
            _ -> :IDENTIFIER
          end

        {String.length(token), Token.add(type, token)}
    end
  end
end
