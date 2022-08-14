defmodule Lexer do
  alias Lexer.BasicTypes
  alias Lexer.Helpers

  def scan(input, mode, line, position, tokens \\ [])

  def scan([], _mode, _line, _position, tokens) do
    tokens
    |> Enum.reject(&(&1 == nil))
  end

  def scan(input, mode, line, position, tokens) do
    [h | t] = input

    token =
      case h do
        "(" ->
          Token.add(:LPAREN, h)

        ")" ->
          Token.add(:RPAREN, h)

        "{" ->
          Token.add(:LBRACE, h)

        "}" ->
          Token.add(:RBRACE, h)

        ":" ->
          Token.add(:COLON, h)

        "[" ->
          Token.add(:LBRACKET, h)

        "]" ->
          Token.add(:RBRACKET, h)

        "," ->
          Token.add(:COMMA, h)

        "." ->
          Token.add(:DOT, h)

        "+" ->
          Token.add(:ADD, h)

        "-" ->
          [next | t] = t

          cond do
            next == ">" ->
              {2, Token.add(:ARROW, "->")}

            next =~ ~r/\d/ ->
              {length, number} = BasicTypes.add_number(next, t, -1, line, position)
              {length + 1, number}

            true ->
              {1, Token.add(:SUB, "-")}
          end

        "*" ->
          Token.add(:MUL, h)

        "/" ->
          Token.add(:DIV, h)

        "^" ->
          Token.add(:POW, h)

        ";" ->
          Token.add(:SEMICOLON, h)

        "=" ->
          Token.add(:EQ, h)

        "!" ->
          next = Helpers.match_next("=", t)
          token = Token.add((next && :NEQ) || :NOT, (next && "!=") || "!")
          {String.length(token.lexeme), token}

        ">" ->
          next = Helpers.match_next("=", t)
          token = Token.add((next && :GE) || :GT, (next && ">=") || ">")
          {String.length(token.lexeme), token}

        "<" ->
          next = Helpers.match_next("=", t)
          token = Token.add((next && :LE) || :LT, (next && "<=") || "<")
          {String.length(token.lexeme), token}

        "\"" ->
          case BasicTypes.add_string(t) do
            {length, :err} ->
              Magnolia.error({line, position}, "unterminated string")
              {length, nil}

            token ->
              token
          end

        "#" ->
          Helpers.comment(t)

        "\n" ->
          {:new_line, line + 1}

        s when s in [" ", "\n", "\t", "\r"] ->
          nil

        _ ->
          cond do
            h =~ ~r/\d/ ->
              BasicTypes.add_number(h, t, 1, line, position)

            h =~ ~r/[a-zA-Z_@]/ ->
              BasicTypes.add_identifier([h | t])

            true ->
              char = String.replace(inspect(h), "\"", "")

              Magnolia.error({line, position}, "unexpected character: #{char}")
              nil
          end
      end

    case token do
      {:new_line, num} ->
        if mode == :file do
          scan(t, mode, num, 0, tokens)
        else
          scan(t, mode, line, 0, tokens)
        end

      {length, :comment} ->
        scan(Enum.drop(t, length), mode, line, position, tokens)

      {length, token} ->
        scan(Enum.drop(t, length - 1), mode, line, position + length, tokens ++ [token])

      nil ->
        scan(t, mode, line, position + 1, tokens)

      _ ->
        scan(t, mode, line, position, tokens ++ [token])
    end
  end
end
