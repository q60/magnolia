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

    args =
      cond do
        args =~ ~r/\[.*\]/ ->
          String.slice(args, 1..-2)

        true ->
          args
      end

    module_check =
      case Code.string_to_quoted!(module) do
        {_, _, [Elixir | modules]} ->
          if List.first(modules) in [:Magnolia, :Lexer, :Parser, :Token] do
            Magnolia.error("undefined module")
            :err
          else
            true
          end

        _ ->
          true
      end

    case module_check do
      :err ->
        stack

      _ ->
        {res, _} = Code.eval_string("#{module}.#{func}(#{args})")
        [res | Enum.drop(stack, 1)]
    end
  end
end
