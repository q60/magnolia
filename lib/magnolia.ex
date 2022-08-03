defmodule Magnolia do
  defp prompt() do
    # TODO
  end

  defp run_file(_src) do
    # TODO
  end

  def main(args) do
    case args do
      []    -> prompt()
      [src] -> run_file(src)
      _     -> IO.puts("\x1B[93musage:\x1B[0m magnolia [file]")
    end
  end
end
