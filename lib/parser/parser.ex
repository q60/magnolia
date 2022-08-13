defmodule Parser do
  alias Parser.ComplexTypes
  alias Parser.Identifiers

  def parse(tokens) do
    tokens
    |> ComplexTypes.add_seqs()
    |> ComplexTypes.add_words()
  end

  def eval(tokens, stack \\ [], dict \\ %{})

  def eval([], stack, dict) do
    {stack
     |> Enum.reject(&(&1 == nil)), dict}
  end

  def eval([token | next], stack, dict) do
    case token.type do
      type when type in [:STRING, :LIST, :TUPLE, :NUMBER] ->
        eval(next, [token.lexeme | stack], dict)

      type when type in [:TRUE, :FALSE] ->
        eval(next, [String.to_atom(token.lexeme) | stack], dict)

      :WORD ->
        {name, spec, code} = token.lexeme
        eval(next, stack, Map.put(dict, name, {spec, code}))

      :LAMBDA ->
        eval(next, [token.lexeme | stack], dict)

      :ADD ->
        a = Enum.at(stack, 1)
        b = Enum.at(stack, 0)

        res =
          cond do
            is_number(a) && is_number(b) -> a + b
            is_binary(a) && is_binary(b) -> a <> b
          end

        eval(next, [res | Enum.drop(stack, 2)], dict)

      :SUB ->
        a = Enum.at(stack, 1)
        b = Enum.at(stack, 0)
        eval(next, [a - b | Enum.drop(stack, 2)], dict)

      :MUL ->
        a = Enum.at(stack, 1)
        b = Enum.at(stack, 0)
        eval(next, [a * b | Enum.drop(stack, 2)], dict)

      :EQ ->
        a = Enum.at(stack, 1)
        b = Enum.at(stack, 0)
        eval(next, [a == b | Enum.drop(stack, 2)], dict)

      :NEQ ->
        a = Enum.at(stack, 1)
        b = Enum.at(stack, 0)
        eval(next, [a != b | Enum.drop(stack, 2)], dict)

      :GT ->
        a = Enum.at(stack, 1)
        b = Enum.at(stack, 0)
        eval(next, [a > b | Enum.drop(stack, 2)], dict)

      :LT ->
        a = Enum.at(stack, 1)
        b = Enum.at(stack, 0)
        eval(next, [a < b | Enum.drop(stack, 2)], dict)

      :GE ->
        a = Enum.at(stack, 1)
        b = Enum.at(stack, 0)
        eval(next, [a >= b | Enum.drop(stack, 2)], dict)

      :LE ->
        a = Enum.at(stack, 1)
        b = Enum.at(stack, 0)
        eval(next, [a <= b | Enum.drop(stack, 2)], dict)

      :AND ->
        a = Enum.at(stack, 1)
        b = Enum.at(stack, 0)
        eval(next, [a && b | Enum.drop(stack, 2)], dict)

      :OR ->
        a = Enum.at(stack, 1)
        b = Enum.at(stack, 0)
        eval(next, [a || b | Enum.drop(stack, 2)], dict)

      :NOT ->
        a = Enum.at(stack, 0)
        eval(next, [!a | Enum.drop(stack, 2)], dict)

      :DIV ->
        a = Enum.at(stack, 1)
        b = Enum.at(stack, 0)
        eval(next, [a / b | Enum.drop(stack, 2)], dict)

      :CLEAR ->
        eval(next, [], dict)

      :DROP ->
        eval(next, Enum.drop(stack, 1), dict)

      :DUP ->
        eval(next, [Enum.at(stack, 0) | stack], dict)

      :SWAP ->
        a = Enum.at(stack, 0)
        b = Enum.at(stack, 1)
        eval(next, [b, a] ++ Enum.drop(stack, 2), dict)

      :OVER ->
        a = Enum.at(stack, 1)
        b = Enum.at(stack, 0)
        eval(next, [a, b, a] ++ Enum.drop(stack, 2), dict)

      :IF ->
        bool = Enum.at(stack, 2)
        if_true = Enum.at(stack, 1)
        if_false = Enum.at(stack, 0)

        {stack, dict} =
          if bool do
            eval(if_true, Enum.drop(stack, 3), dict)
          else
            eval(if_false, Enum.drop(stack, 3), dict)
          end

        eval(next, stack, dict)

      :CALL ->
        lambda = Enum.at(stack, 0)
        {stack, dict} = eval(lambda, Enum.drop(stack, 1), dict)
        eval(next, stack, dict)

      :REP ->
        lambda = Enum.at(stack, 1)
        n = Enum.at(stack, 0)

        [_ | t] =
          for _ <- 1..(n) do
            eval(lambda, Enum.drop(stack, 1), dict)
          end

        {stack, dict} = List.last(t)
        eval(next, Enum.drop(stack, 1), dict)

      :PRIN ->
        str = Enum.at(stack, 0)
        IO.write(str)
        eval(next, Enum.drop(stack, 1), dict)

      :PRINT ->
        str = Enum.at(stack, 0)
        IO.puts(str)
        eval(next, Enum.drop(stack, 1), dict)

      :FORMAT ->
        str = Enum.at(stack, 1)
        format = Enum.at(stack, 0)
        :io.format(str, format)
        eval(next, Enum.drop(stack, 2), dict)

      :USE ->
        str = Enum.at(stack, 0)
        {_, lib} =
          File.read!("src/#{str}.mg")
          |> String.graphemes()
          |> Lexer.scan(:file, 1, 0)
          |> Parser.parse()
          |> Parser.eval()

        eval(next, Enum.drop(stack, 1), Map.merge(dict, lib))

      :IDENTIFIER ->
        case String.first(token.lexeme) do
          "@" ->
            eval(
              next,
              Identifiers.eval_native(token, stack),
              dict
            )

          _ ->
            {_spec, tokens} = dict[token.lexeme]
            {stack, dict} = eval(tokens, stack, dict)
            eval(next, stack, dict)
        end

      _ ->
        eval(next, stack, dict)
    end
  end
end
