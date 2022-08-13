defmodule Magnolia do
  defp prompt(counter, data) do
    case IO.gets("    \x1B[33m#{counter}.\x1B[0m \x1B[35m\x1B[1mλ\x1B[0m ") do
      :eof ->
        IO.puts("stopped")
        System.stop()

      input ->
        data = run(input, :prompt, counter, data)
        prompt(counter + 1, data)
    end
  end

  defp run_file(src) do
    case File.read(src) do
      {:ok, input} -> run(input <> "\n", :file, 1)
      {:error, e}  -> IO.puts(:stderr, "error: #{e}")
    end
  end

  defp run(input, mode, line, {stack, dict} \\ {[], %{}}) do
    tokens =
      String.graphemes(input)
      |> Lexer.scan(mode, line, 0)
      |> Parser.parse()
	  # IO.puts("\ntokens:\n\x1B[92m#{tokens |> inspect(pretty: true)}\x1B[0m")

    {stack, dict} = Parser.eval(tokens, stack, dict)

    stack_pretty =
      Enum.reverse(stack)
      |> Enum.map(
        fn elem ->
          cond do
            is_list(elem) and is_struct(List.first(elem)) ->
              "λ: " <> (
	              Enum.map(elem, &(&1.lexeme))
                |> inspect()
              )
            true ->
              inspect(elem)
          end
        end
      )
      |> Enum.join("\n")

    dict_pretty =
      Map.to_list(dict)
      |> Enum.map(
        fn {k, v} ->
          {{_, spec}, _} = v
          "#{:io_lib.format("~-10.. s", [k])}#{spec}"
        end
      )
      |> Enum.join("\n")

	  IO.puts("\ndictionary:\n\x1B[35m#{dict_pretty}\x1B[0m")
	  IO.puts("stack:\n\x1B[35m#{stack_pretty}\x1B[0m")

    {stack, dict}
  end

  def error({line, position}, string) do
    position =
      "~-4.. B|"
      |> :io_lib.format([position])
      |> to_string()

    IO.puts("  \x1B[91m#{line}:#{position} \x1B[1m#{string}\x1B[0m")
  end

  def main(args) do
    core_lib = File.read!("src/core.mg")

    {_, dict} =
      String.graphemes(core_lib)
      |> Lexer.scan(:file, 1, 0)
      |> Parser.parse()
      |> Parser.eval()

    case args do
      []    -> prompt(1, {[], dict})
      [src] -> run_file(src)
      _     -> IO.puts("\x1B[93musage:\x1B[0m magnolia [file]")
    end
  end
end
