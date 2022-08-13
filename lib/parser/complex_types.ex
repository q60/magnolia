defmodule Parser.ComplexTypes do
  def add_seqs(tokens, result \\ [])
  def add_seqs([], result), do: result
  def add_seqs([token | next], result) do
    case token.type do
	    :LBRACE   ->
        {num_tokens, list} = add_seq(next, {:LIST, :RBRACE})
        add_seqs(Enum.drop(next, num_tokens + 1), result ++ [list])
	    :LPAREN   ->
        {num_tokens, tuple} = add_seq(next, {:TUPLE, :RPAREN})
        add_seqs(Enum.drop(next, num_tokens + 1), result ++ [tuple])
	    :LBRACKET ->
        {num_tokens, spec} = add_spec(next)
        add_seqs(Enum.drop(next, num_tokens + 1), result ++ [spec])
      :DOT      ->
        if List.first(next).type == :LBRACE do
          {num_tokens, lambda} = add_seq(Enum.drop(next, 1), {:LAMBDA, :RBRACE})
          add_seqs(Enum.drop(next, num_tokens + 1), result ++ [lambda])
        end
		  _         ->
        add_seqs(next, result ++ [token])
    end
  end

  def add_words(tokens, result \\ [])
  def add_words([], result), do: result
  def add_words([token | next], result) do
    case token.type do
	    :COLON ->
        {num_tokens, word} = add_word(next)
        add_words(Enum.drop(next, num_tokens + 1), result ++ [word])
		  _      ->
        add_words(next, result ++ [token])
    end
  end


  defp add_seq(chars, seq, list \\ [])
  defp add_seq([], _, _), do: :err
  defp add_seq([token | next], {seq_type, term}, list) do
	  case token.type do
      ^term ->
        res = seq_type == :TUPLE && List.to_tuple(list) || list
        {length(list), Token.add(seq_type, res)}
      _     ->
        elem = seq_type == :LAMBDA && token || token.lexeme
        add_seq(next, {seq_type, term}, list ++ [elem])
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
        {length(spec), Token.add(:SPEC, {[in: b, out: a - b], "[ #{Enum.join(spec, " ")} ]"})}
      _         ->
        add_spec(next, spec ++ [token.lexeme])
    end
  end

  defp add_word(chars, word \\ [])
  defp add_word([], _), do: :err
  defp add_word([token | next], word) do
	  case token.type do
      :SEMICOLON ->
        [name, spec | code] = word
        {length(word), Token.add(:WORD, {name.lexeme, spec.lexeme, code})}
      _          ->
        add_word(next, word ++ [token])
    end
  end
end
