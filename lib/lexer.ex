defmodule Lexer do
  def scan(input, mode, line, position, tokens \\ [])
  def scan([], _mode, _line, _position, tokens) do
    tokens
    |> Enum.reject(&(&1 == nil))
  end
  def scan(input, mode, line, position, tokens) do
	  [h | t] = input
    token =
      case h do
        "("  -> add_token(:LPAREN, h)
        ")"  -> add_token(:RPAREN, h)
        "{"  -> add_token(:LBRACE, h)
        "}"  -> add_token(:RBRACE, h)
        ","  -> add_token(:COMMA, h)
        "."  -> add_token(:DOT, h)
        "+"  -> add_token(:ADD, h)
        "-"  -> add_token(:SUB, h)
        "*"  -> add_token(:MUL, h)
        "/"  -> add_token(:DIV, h)
        ";"  -> add_token(:SEMICOLON, ";")
        "!"  -> next = match_next("=", t)
                token = add_token(next && :NEQ || :NOT, next && "!=" || "!")
                {String.length(token.lexeme), token}
        "="  -> next = match_next("=", t)
                token = add_token(next && :EQ || :ASSIGN, next && "==" || "=")
                {String.length(token.lexeme), token}
        ">"  -> next = match_next("=", t)
                token = add_token(next && :GE || :GT, next && ">=" || ">")
                {String.length(token.lexeme), token}
        "<"  -> next = match_next("=", t)
                token = add_token(next && :LE || :LT, next && "<=" || "<")
                {String.length(token.lexeme), token}
        "\"" -> case add_string(t) do
                  {length, :err} -> Magnolia.error({line, position}, "unterminated string")
                                    {length, nil}
                  token          -> token
                end
        "#"  -> comment(t)
        "\n" -> {:new_line, line + 1}
        s when s in [" ", "\n", "\t", "\r"] -> nil
        _    -> cond do
                  Regex.match?(~r/\d/, h) ->
	                  case add_number([h | t]) do
                      {length, :err} -> Magnolia.error({line, position}, "malformed number")
                                        {length, nil}
                      token          -> token
                    end
                  Regex.match?(~r/[a-zA-Z_]/, h) ->
                    add_identifier([h | t])
                  true ->
                    char =
                      inspect(h)
                      |> String.replace("\"", "")
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


  defp add_token(token_type, token_lexeme) do
	  add_token(token_type, token_lexeme, nil)
  end
  defp add_token(token_type, token_lexeme, token_literal) do
    %Token{
      type: token_type,
      lexeme: token_lexeme,
      literal: token_literal
    }
  end

  defp add_string([char | next], string \\ "") do
	  case char do
      "\"" -> {String.length(string) + 2, add_token(:STRING, string)}
      "\n" -> {String.length(string) + 2, :err}
      _    -> add_string(next, string <> char)
    end
  end

  defp add_number([char | next], number \\ "") do
    decimal_points = (String.graphemes(number) |> Enum.frequencies())["."]

	  cond do
      Regex.match?(~r/[\d\.]/, char) ->
        add_number(next, number <> char)
      decimal_points != nil && decimal_points > 1 ->
        {String.length(number), :err}
      true ->
        {float, _} = Float.parse(number)
        {String.length(number), add_token(:NUMBER, float)}
    end
  end

  def add_identifier([char | next], token \\ "") do
	  cond do
      Regex.match?(~r/[a-zA-Z\d_]/, char) ->
        add_identifier(next, token <> char)
      true ->
        type =
          case token do
	          "and"    -> :AND
		        "or"     -> :OR
            "if"     -> :IF
            "else"   -> :ELSE
            "while"  -> :WHILE
            "for"    -> :FOR
            "true"   -> :TRUE
            "false"  -> :FALSE
            "nil"    -> :NIL
            "print"  -> :PRINT
            "var"    -> :VAR
            "return" -> :RETURN
            _        -> :IDENTIFIER
          end
        {String.length(token), add_token(type, token)}
    end
  end

  defp comment([char | next], length \\ 0) do
    case char do
      "\n" -> {length, :comment}
      _    -> comment(next, length + 1)
    end
  end

  defp match_next(char, [next | _]) do
    char == next
  end
end
