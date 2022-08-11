defmodule Magnolia do
  defp prompt(counter, stack \\ []) do
    case IO.gets("    \x1B[33m#{counter}.\x1B[0m \x1B[35m\x1B[1mλ\x1B[0m ") do
      :eof ->
        IO.puts("stopped")
        System.stop()

      input ->
        IO.write("\n")
        stack = run(input, :prompt, counter, stack)
        prompt(counter + 1, stack)
    end
  end

  defp run_file(src) do
    case File.read(src) do
      {:ok, input} -> run(input <> "\n", :file, 1)
      {:error, e}  -> IO.puts(:stderr, "error: #{e}")
    end
  end

  defp run(input, mode, line, stack \\ []) do
    tokens = Lexer.scan(String.graphemes(input), mode, line, 0)
    stack = Parser.eval(tokens, stack)

	  # IO.puts("\ntokens:\n\x1B[92m#{tokens |> inspect(pretty: true)}\x1B[0m")
	  IO.puts("stack:\n\x1B[92m#{stack |> Enum.reverse |> Enum.join("\n")}\x1B[0m")
    stack
  end

  def error({line, position}, string) do
    position =
      "~-4.. B|"
      |> :io_lib.format([position])
      |> to_string()

    IO.puts("  \x1B[91m#{line}:#{position} \x1B[1m#{string}\x1B[0m")
  end

  def main(args) do
    case args do
      []    -> prompt(1)
      [src] -> run_file(src)
      _     -> IO.puts("\x1B[93musage:\x1B[0m magnolia [file]")
    end
  end
end
