defmodule Token do
	defstruct [:type,
             :lexeme,
             :line]

  def add(token_type, token_lexeme) do
    %Token{
      type: token_type,
      lexeme: token_lexeme
    }
  end
end
