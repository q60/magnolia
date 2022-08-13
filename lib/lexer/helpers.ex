defmodule Lexer.Helpers do
  def match_next(char, [next | _]) do
    char == next
  end

  def comment([char | next], length \\ 0) do
    case char do
      "\n" -> {length, :comment}
      _    -> comment(next, length + 1)
    end
  end
end
