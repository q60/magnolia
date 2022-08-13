defmodule Parser.Identifiers do
  def eval_native(token, stack) do
    identifier =
      Regex.scan(~r/[a-z_]+/i, token.lexeme)
      |> List.flatten()

    module = Enum.drop(identifier, -1)

    module =
      case List.first(identifier) do
        "ex" ->
          "Elixir." <>
            (Enum.map(
               module,
               fn
                 "io" -> "IO"
                 m -> String.capitalize(m)
               end
             )
             |> Enum.drop(1)
             |> Enum.join("."))

        "erl" ->
          ":" <>
            (Enum.drop(module, 1)
             |> Enum.join("."))
      end

    func = List.last(identifier) |> String.downcase()

    args =
      List.first(stack)
      |> inspect()
      |> String.replace(["[", "]"], "")

    {res, _} = Code.eval_string("#{module}.#{func}(#{args})")
    [res | Enum.drop(stack, 1)]
  end
end
