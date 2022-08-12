defmodule Lexer do
  def scan(input, mode, line, position, tokens \\ [])
  def scan([], _mode, _line, _position, tokens) do
    tokens
    |> Enum.reject(&(&1 == nil))
    |> add_seqs()
  end
  def scan(input, mode, line, position, tokens) do
	  [h | t] = input
    token =
      case h do
        "("  -> add_token(:LPAREN, h)
        ")"  -> add_token(:RPAREN, h)
        "{"  -> add_token(:LBRACE, h)
        "}"  -> add_token(:RBRACE, h)
        ":"  -> add_token(:COLON, h)
        "["  -> add_token(:LBRACKET, h)
        "]"  -> add_token(:RBRACKET, h)
        ","  -> add_token(:COMMA, h)
        "."  -> add_token(:DOT, h)
        "+"  -> add_token(:ADD, h)
        # "-"  -> add_token(:SUB, h)
        "-"  ->
          next = match_next(">", t)
          token = add_token(next && :ARROW || :SUB, next && "->" || "-")
          {String.length(token.lexeme), token}
        "*"  -> add_token(:MUL, h)
        "/"  -> add_token(:DIV, h)
        ";"  -> add_token(:SEMICOLON, h)
        "!"  ->
          next = match_next("=", t)
          token = add_token(next && :NEQ || :NOT, next && "!=" || "!")
          {String.length(token.lexeme), token}
        "="  ->
          next = match_next("=", t)
          token = add_token(next && :EQ || :ASSIGN, next && "==" || "=")
          {String.length(token.lexeme), token}
        ">"  ->
          next = match_next("=", t)
          token = add_token(next && :GE || :GT, next && ">=" || ">")
          {String.length(token.lexeme), token}
        "<"  ->
          next = match_next("=", t)
          token = add_token(next && :LE || :LT, next && "<=" || "<")
          {String.length(token.lexeme), token}
        "\"" ->
          case add_string(t) do
            {length, :err} ->
              Magnolia.error({line, position}, "unterminated string")
              {length, nil}
            token ->
              token
          end
        "#"  -> comment(t)
        "\n" -> {:new_line, line + 1}
        s when s in [" ", "\n", "\t", "\r"] -> nil
        _    ->
          cond do
            Regex.match?(~r/\d/, h) ->
              [base_char | next] = t
              base = %{"x" => 16, "o" => 8, "b" => 2}[base_char]
              number =
                if base == nil do
                  add_number([h | t], 10)
                else
                  {length, num} = add_number(next, base)
                  {length + 2, num}
                end
	            case number do
                {length, :err} ->
                  Magnolia.error({line, position}, "malformed number")
                  {length, nil}
                token ->
                  token
              end

            Regex.match?(~r/[a-zA-Z_@]/, h) ->
              add_identifier([h | t])

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


  defp add_token(token_type, token_lexeme) do
    %Token{
      type: token_type,
      lexeme: token_lexeme
    }
  end

  defp add_seqs(tokens, result \\ [])
  defp add_seqs([], result), do: result
  defp add_seqs([token | next], result) do
    case token.type do
	    :LBRACE   ->
        {num_tokens, list} = add_list(next)
        add_seqs(Enum.drop(next, num_tokens + 1), result ++ [list])
	    :LPAREN   ->
        {num_tokens, tuple} = add_tuple(next)
        add_seqs(Enum.drop(next, num_tokens + 1), result ++ [tuple])
	    :LBRACKET ->
        {num_tokens, spec} = add_spec(next)
        add_seqs(Enum.drop(next, num_tokens + 1), result ++ [spec])
		  _         ->
        add_seqs(next, result ++ [token])
    end
  end

  defp add_spec(chars, spec \\ [])
  defp add_spec([], _), do: :err
  defp add_spec([token | next], spec) do
	  case token.type do
      :RBRACKET ->
        {a, b, _} =
          Enum.reduce(spec, {0, 0, 0},
            fn x, {a, b, i} ->
              cond do
	              x == "->" -> {a, a, i + 1}
                true      -> {a + 1, b, i + 1}
              end
            end
          )
        {
          length(spec),
          add_token(:SPEC, [in: b, out: a - b])
        }
      _         -> add_spec(next, spec ++ [token.lexeme])
    end
  end

  defp add_list(chars, list \\ [])
  defp add_list([], _), do: :err
  defp add_list([token | next], list) do
	  case token.type do
      :RBRACE -> {length(list), add_token(:LIST, list)}
      _       -> add_list(next, list ++ [token.lexeme])
    end
  end

  defp add_tuple(chars, list \\ [])
  defp add_tuple([], _), do: :err
  defp add_tuple([token | next], list) do
	  case token.type do
      :RPAREN -> {length(list), add_token(:TUPLE, List.to_tuple(list))}
      _       -> add_tuple(next, list ++ [token.lexeme])
    end
  end

  defp add_string(chars, string \\ "")
  defp add_string([], string), do: {String.length(string) + 2, :err}
  defp add_string([char | next], string) do
	  case char do
      "\"" -> {String.length(string) + 2, add_token(:STRING, string)}
      _    -> add_string(next, string <> char)
    end
  end

  defp add_number([char | next], base, number \\ "") do
    decimal_points = (String.graphemes(number) |> Enum.frequencies())["."]

	  cond do
      Regex.match?(~r/[\d\.]/, char) ->
        add_number(next, base, number <> char)
      decimal_points != nil && decimal_points > 1 ->
        {String.length(number), :err}
      decimal_points != nil && decimal_points == 1 ->
        {float, _} = Float.parse(number)
        {String.length(number), add_token(:NUMBER, float)}
      true ->
        {integer, _} = Integer.parse(number, base)
        {String.length(number), add_token(:NUMBER, integer)}
    end
  end

  defp add_identifier([char | next], token \\ "") do
	  cond do
      Regex.match?(~r/[a-zA-Z\.\d_@]/, char) ->
        add_identifier(next, token <> char)
      true ->
        type =
          case token do
	          "and"    -> :AND
		        "or"     -> :OR
            "if"     -> :IF
            "while"  -> :WHILE
            "for"    -> :FOR
            "true"   -> :TRUE
            "false"  -> :FALSE
            "print"  -> :PRINT
            "drop"   -> :DROP
            "swap"   -> :SWAP
            "dup"    -> :DUP
            "rep"    -> :REP
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
