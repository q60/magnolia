defmodule Lexer do
  def scan(input, tokens \\ [])
  def scan([], tokens) do
    tokens
  end
  def scan(input, tokens) do
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
        "!"  -> next = match_next("=", t)
                {next, add_token(next && :NEQ || :NOT, next && "!=" || "!")}
        "="  -> next = match_next("=", t)
                {next, add_token(next && :EQ || :ASSIGN, next && "==" || "=")}
        ">"  -> next = match_next("=", t)
                {next, add_token(next && :GE || :GT, next && ">=" || ">")}
        "<"  -> next = match_next("=", t)
                {next, add_token(next && :LE || :LT, next && "<=" || "<")}
        ";"  -> add_token(:SEMICOLON, ";")
        "\n" -> add_token(:SEMICOLON, ";")
        _    -> Magnolia.error("unexpected characted")
      end

    case token do
	    {true, token} ->
        [_ | skip] = t
        scan(skip, tokens ++ [token])
      {false, token} ->
        scan(t, tokens ++ [token])
      _ ->
        scan(t, tokens ++ [token])
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

  defp match_next(char, [next | _]) do
    char == next
  end
end
