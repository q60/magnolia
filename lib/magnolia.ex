defmodule Magnolia do
  defp prompt(counter \\ 1) do
    case IO.gets("\x1B[93m#{counter}\x1B[0m> ") do
      :eof ->
        IO.puts("stopped")
        System.stop()

      input ->
        run(input, :prompt, counter)
        prompt(counter + 1)
    end
  end

  defp run_file(src) do
    case File.read(src) do
      {:ok, input} -> run(input, :file, 1)
      {:error, e}  -> IO.puts(:stderr, "error: #{e}")
    end
  end

  defp run(input, mode, line) do
    tokens =
      Lexer.scan(String.graphemes(input), mode, line, 0)
      |> inspect(pretty: true)

	  IO.puts("\x1B[92m#{tokens}\x1B[0m")
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
      []    -> prompt()
      [src] -> run_file(src)
      _     -> IO.puts("\x1B[93musage:\x1B[0m magnolia [file]")
    end
  end
end
