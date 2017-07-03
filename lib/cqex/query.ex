defmodule CQEx.Query do
  require Record

  import CQEx, only: :macros
  import CQEx.Helpers

  alias :cqerl, as: CQErl

  defmacro __using__(_opts) do
    quote do
      import CQEx.Query.Sigil
      alias CQEx.Query, as: Q
    end
  end

  @default_consistency 1

  defstruct statement: "",
    values: %{},
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
    case q do
      %CQEx.Query{statement: statement, values: values} when is_binary(statement) ->
        {{statement, values}, CQErl.run_query(client, convert(q))}
      %CQEx.Query{} ->
        CQErl.run_query client, convert q
      any ->
        CQErl.run_query client, any
    end
    |> case do
      {_, {:ok, result}} ->
        {:ok, CQEx.Result.convert(result, client)};

      {:ok, result} ->
        {:ok, CQEx.Result.convert(result, client)};

      {:error, {:error, {reason, stacktrace}}} ->
        %{ msg: "CQErl processing error: #{reason}", acc: stacktrace };

      {{s, v}, {:error, {code, message, _extras}}} ->
        %{ msg: "#{message} (Code #{code})\nStatement: #{s}\nValues: #{inspect(v)}", acc: [] }

      {:error, {code, message, _extras}} ->
        %{ msg: "#{message} (Code #{code})", acc: [] }
    end
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

  def put(q = %CQEx.Query{ values: values }, key, value) do
    values = values || %{}
    %{ q | values: Map.put(values, key, value) }
  end
  def get(%CQEx.Query{ values: values }, key, default \\ nil) do
    Map.get((values || %{}), key, default)
  end
  def delete(q = %CQEx.Query{ values: values }, key) do
    values = values || %{}
    %{ q | values: Map.delete(values, key) }
  end
  def merge(q = %CQEx.Query{ values: values }, other) do
    values = values || %{}
    %{ q | values: Map.merge(values, other) }
  end

  def new do
    %CQEx.Query{}
  end

  def statement(q = %CQEx.Query{}, statement) do
    %{ q | statement: statement }
  end
  def page_size(q = %CQEx.Query{}, page_size) when is_integer(page_size) do
    %{ q | page_size: page_size }
  end
  def consistency(q = %CQEx.Query{}, consistency) do
    %{ q | consistency: consistency }
  end
  def serial_consistency(q = %CQEx.Query{}, serial_consistency) do
    %{ q | serial_consistency: serial_consistency }
  end

  defp nullify(rec), do: nullify(rec, :null)
  defp nullify(rec, fallback) when is_map(rec) do
    rec
    |> Enum.map(fn
      {key, nil} -> {key, fallback};
      {key, other} -> {key, nullify(other)}
    end)
    |> Enum.into(%{})
  end
  defp nullify(list = [{_key, _value} | _rest], fallback) do
    list
    |> Enum.map(fn
      {key, nil} -> {key, fallback};
      {key, other} -> {key, nullify(other)}
    end)
  end
  defp nullify(list = [_value | _rest], fallback) do
    list
    |> Enum.map(fn
      nil -> fallback;
      other -> other
    end)
  end
  defp nullify(nil, fallback), do: fallback
  defp nullify(other, _fallback), do: other

  defmodule Sigil do
    def sigil_q(statement, _modifiers) do
      %CQEx.Query{statement: statement}
    end
  end

end
