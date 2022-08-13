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

  def add_number(h, chars, sign, line, position) do
    [base_char | next] = chars
    base = %{"x" => 16, "o" => 8, "b" => 2}[base_char]

    number =
      if base == nil do
        add_number([h | chars], 10, sign)
      else
        {length, num} = add_number(next, base, sign)
        {length + 2, num}
      end

    case number do
      {length, :err} ->
        Magnolia.error({line, position}, "malformed number")
        {length, nil}

      token ->
        token
    end
  end

  defp add_number([char | next], base, sign, number \\ "") do
    decimal_points = (String.graphemes(number) |> Enum.frequencies())["."]

    cond do
      char =~ ~r/[\d\.]/ ->
        add_number(next, base, sign, number <> char)

      decimal_points != nil && decimal_points > 1 ->
        {String.length(number), :err}

      decimal_points != nil && decimal_points == 1 ->
        {float, _} = Float.parse(number)
        {String.length(number), Token.add(:NUMBER, sign * float)}

      true ->
        {integer, _} = Integer.parse(number, base)
        {String.length(number), Token.add(:NUMBER, sign * integer)}
    end
  end

  def add_identifier([char | next], token \\ "") do
    cond do
      char =~ ~r/[a-zA-Z\.\d_\->@]/ ->
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
            "prin" -> :PRIN
            "print" -> :PRINT
            "format" -> :FORMAT
            "use" -> :USE
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
