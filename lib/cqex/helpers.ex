defmodule CQEx.Helpers do

  @moduledoc "Helper macros"
  defmacro __using__(_opts) do
    quote do
      import CQEx.Helpers
    end
  end

  @doc """
  Helps defining a function like `new!` calling function `new`

  When `new` returns `{:ok, value}`, `new!` returns `value`

  When `new` returns `{:error, reason}`, `new!` raises an exception
  """
  defmacro defbang({ name, _, args }) do
    args = if args |> is_list do
      args
    else
      []
    end

    {:__block__, [], quoted} =
    quote bind_quoted: [name: Macro.escape(name), args: Macro.escape(args)] do
      def unquote(to_string(name) <> "!" |> String.to_atom)(unquote_splicing(args)) do
        case unquote(name)(unquote_splicing(args)) do
          :ok -> :ok
          nil -> nil
          { :ok, result } ->
            result

          { :error, reason } ->
            raise CQEx.Error, msg: reason, acc: unquote(args)

          %{msg: msg, acc: acc} = err ->
            raise CQEx.Error, msg: msg, acc: acc
        end
      end
    end
    {:__block__, [], [{:@, [context: CQEx.Helpers, import: Kernel], [{:doc, [], ["See "<>to_string(name)<>"/"<>to_string(args |> length)]}]}|quoted]}
  end
end
