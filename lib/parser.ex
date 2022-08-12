defmodule Parser do
  def eval(tokens, stack \\ [])
  def eval([], stack) do
    stack
    |> Enum.reject(&(&1 == nil))
  end
	def eval([token | next], stack) do
    case token.type do
      type when type in [:STRING, :LIST, :TUPLE, :NUMBER] ->
        eval(next, [token.lexeme | stack])
      :ADD    ->
        a = Enum.at(stack, 1)
        b = Enum.at(stack, 0)
        res =
          cond do
	          is_number(a) && is_number(b) -> a + b
            is_binary(a) && is_binary(b) -> a <> b
          end
        eval(next, [res | Enum.drop(stack, 2)])
      :SUB    ->
        a = Enum.at(stack, 1)
        b = Enum.at(stack, 0)
        eval(next, [a - b | Enum.drop(stack, 2)])
      :MUL    ->
        a = Enum.at(stack, 1)
        b = Enum.at(stack, 0)
        eval(next, [a * b | Enum.drop(stack, 2)])
      :DIV    ->
        a = Enum.at(stack, 1)
        b = Enum.at(stack, 0)
        eval(next, [a / b | Enum.drop(stack, 2)])
	    :DROP   ->
        eval(next, Enum.drop(stack, 1))
	    :DUP    ->
        eval(next, [Enum.at(stack, 0) | stack])
	    :SWAP   ->
        a = Enum.at(stack, 0)
        b = Enum.at(stack, 1)
        eval(next, [b, a] ++ Enum.drop(stack, 2))
	    :REP    ->
        n = Enum.at(stack, 0)
        str = Enum.at(stack, 1)
        eval(next, [String.duplicate(str, n) | Enum.drop(stack, 2)])
	    :PRINT  ->
        IO.puts(List.first(stack))
        eval(next, Enum.drop(stack, 1))
      :IDENTIFIER ->
        case String.first(token.lexeme) do
	        "@" ->
            eval(
              next,
              Parser.Identifiers.eval_native(token, stack)
            )
        end
      _       ->
        eval(next, stack)
    end
  end
end
