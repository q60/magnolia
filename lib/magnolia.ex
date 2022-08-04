defmodule Magnolia do
  defp prompt(counter \\ 1) do
    case IO.gets("\x1B[93m#{counter}\x1B[0m> ") do
      :eof ->
        IO.puts("stopped")
        System.stop()

      input ->
        run(input)
        prompt(counter + 1)
    end
  end

  defp run_file(src) do
    case File.read(src) do
      {:ok, input} -> run(input)
      {:error, e}  -> IO.puts(:stderr, "error: #{e}")
    end
  end

  defp run(input) do
	  Lexer.scan(String.graphemes(input))
    |> IO.inspect()
  end

  def error(string) do
	  raise string
  end

  def main(args) do
    case args do
      []    -> prompt()
      [src] -> run_file(src)
      _     -> IO.puts("\x1B[93musage:\x1B[0m magnolia [file]")
    end
  end
end
