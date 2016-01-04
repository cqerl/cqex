defmodule CQEx.Query do
  require Record

  import CQEx, only: :macros
  import CQEx.Helpers

  alias :cqerl, as: CQErl

  @default_consistency 1

  defstruct statement: "",
    values: [],
    reusable: nil,
    named: false,
    page_size: 100,
    page_state: nil,
    consistency: @default_consistency,
    serial_consistency: nil,
    value_encode_handler: nil

  def convert(%CQEx.Query{
    :statement => statement,
    :values => values,
    :reusable => reusable,
    :named => named,
    :page_size => page_size,
    :page_state => page_state,
    :consistency => consistency,
    :serial_consistency => serial_consistency,
    :value_encode_handler => value_encode_handler
    }) do
    cql_query(
      statement: statement,
      values: nullify(values, :undefined),
      reusable: nullify(reusable, :undefined),
      named: nullify(named, :undefined),
      page_size: nullify(page_size, :undefined),
      page_state: nullify(page_state, :undefined),
      consistency: nullify(consistency, :undefined),
      serial_consistency: nullify(serial_consistency, :undefined),
      value_encode_handler: nullify(value_encode_handler, :undefined)
    )
  end
  def convert(q) when Record.is_record(q, :cql_query) do
    [{:__struct__, CQEx.Query} | cql_query(q)] |> Enum.into(%{})
  end
  def convert(res), do: res

  def call(c, q) do
    client = CQEx.Client.get c
    {:ok, result} = case q do
      %CQEx.Query{} ->
        CQErl.run_query client, convert q
      any ->
        CQErl.run_query client, any
    end
    {:ok, CQEx.Result.convert(result, client)}
  end
  defbang call(a, b)

  def cast(c, q) do
    client = CQEx.Client.get c
    current = self()

    spawn_link fn ->
      tag = case q do
        %CQEx.Query{} ->
          CQErl.send_query client, convert q
        any ->
          CQErl.send_query client, any
      end
      send current, {:tag, tag}

      receive do
        {:result, ^tag, result} ->
          send current, {:result, tag, CQEx.Result.convert(result, client)}
        any ->
          send current, any
      end
    end

    receive do
      {:tag, tag} -> tag
    end
  end

  defp nullify(rec), do: nullify(rec, :null)
  defp nullify(rec, fallback) when is_map(rec) do
    rec
    |> Enum.map(fn
      {key, nil} -> {key, fallback};
      {key, other} -> {key, nullify(other)}
    end)
    |> Enum.into %{}
  end
  defp nullify(list = [{key, value} | rest], fallback) do
    list
    |> Enum.map fn
      {key, nil} -> {key, fallback};
      {key, other} -> {key, nullify(other)}
    end
  end
  defp nullify(list = [value | rest], fallback) do
    list
    |> Enum.map fn
      nil -> fallback;
      other -> other
    end
  end
  defp nullify(nil, fallback), do: fallback
  defp nullify(other, fallback), do: other
end
