defmodule CQEx.Query do
  @moduledoc false

  require Record

  import CQEx, only: :macros

  defmacro __using__(_opts) do
    quote do
      import CQEx.Query.Sigil
      alias CQEx.Query, as: Q
    end
  end

  @default_consistency 1

  @type valid_query :: iodata() | CQEx.cql_query() | CQEx.cql_query_batch() | CQEx.Query.t()

  defstruct statement: "",
            values: %{},
            reusable: nil,
            named: false,
            page_size: 100,
            page_state: nil,
            consistency: @default_consistency,
            serial_consistency: nil,
            value_encode_handler: nil

  @spec(
    convert(CQEx.Query.t()) :: CQEx.cql_query(),
    convert(CQEx.cql_query()) :: CQEx.Query.t()
  )
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
      values: nullify(values, :null),
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
    Enum.into([{:__struct__, CQEx.Query} | cql_query(q)], %{})
  end

  def convert(res), do: res

  @spec call(CQEx.Client.client_value(), valid_query) ::
          {:ok, map} | {:error, %{acc: any, msg: <<_::64, _::_*8>>}}
  def call(c, q) do
    client = CQEx.Client.get(c)

    case q do
      %CQEx.Query{statement: statement, values: values} when is_binary(statement) ->
        {{statement, values}, :cqerl.run_query(client, convert(q))}

      %CQEx.Query{} ->
        :cqerl.run_query(client, convert(q))

      any ->
        :cqerl.run_query(client, any)
    end
    |> case do
      {_, {:ok, result}} ->
        {:ok, CQEx.Result.convert(result, client)}

      {:ok, result} ->
        {:ok, CQEx.Result.convert(result, client)}

      {:error, {:error, {reason, stacktrace}}} ->
        {:error, %{msg: ":cqerl processing error: #{reason}", acc: stacktrace}}

      {{s, v}, {:error, {code, message, _extras}}} ->
        {:error,
         %{msg: "#{message} (Code #{code})\nStatement: #{s}\nValues: #{inspect(v)}", acc: []}}

      {:error, {code, message, _extras}} ->
        {:error, %{msg: "#{message} (Code #{code})", acc: []}}
    end
  end

  @spec call!(CQEx.Client.client_value(), valid_query) :: CQEx.Result.t()
  def call!(c, q) do
    case call(c, q) do
      {:ok, result} ->
        result

      {:error, %{msg: msg, acc: acc}} ->
        raise CQEx.Error, msg: msg, acc: acc
    end
  end

  require Logger

  @spec cast(CQEx.Client.client_value(), valid_query) :: reference()
  def cast(c, q) do
    client = CQEx.Client.get(c)
    current = self()

    spawn_link(fn ->
      tag =
        case q do
          %CQEx.Query{} ->
            :cqerl.send_query(client, convert(q))

          any ->
            :cqerl.send_query(client, any)
        end

      send(current, {:tag, tag})

      receive do
        {:result, ^tag, result} ->
          send(current, {:result, tag, CQEx.Result.convert(result, client)})

        any ->
          send(current, any)
      end
    end)

    receive do
      {:tag, tag} -> tag
    end
  end

  @spec put(CQEx.Query.t()) :: CQEx.Query.t()
  def put(q = %CQEx.Query{values: nil}) do
    put(%{q | values: %{}})
  end

  def put(q = %CQEx.Query{}) do
    q
  end

  @spec put(CQEx.Query.t(), any, any) :: CQEx.Query.t()
  def put(q = %CQEx.Query{values: values}, key, value) when is_map(values) do
    %{q | values: Map.put(values, key, value)}
  end

  def put(q = %CQEx.Query{values: values}, key, value) when is_list(values) do
    %{q | values: Keyword.put(values, key, value)}
  end

  @spec get(CQEx.Query.t(), any, any) :: any
  def get(query, key, default \\ nil)

  def get(%CQEx.Query{values: nil}, _, default) do
    default
  end

  def get(%CQEx.Query{values: values}, key, default) when is_map(values) do
    Map.get(values, key, default)
  end

  def get(%CQEx.Query{values: values}, key, default) when is_list(values) do
    Keyword.get(values, key, default)
  end

  @spec delete(CQEx.Query.t(), any) :: CQEx.Query.t()
  def delete(q = %CQEx.Query{values: nil}, _key) do
    q
  end

  def delete(q = %CQEx.Query{values: values}, key) when is_map(values) do
    %{q | values: Map.delete(values, key)}
  end

  def delete(q = %CQEx.Query{values: values}, key) when is_list(values) do
    %{q | values: Keyword.delete(values, key)}
  end

  @spec merge(CQEx.Query.t(), Keyword.t() | Map.t()) :: CQEx.Query.t()
  def merge(q = %CQEx.Query{values: nil}, other) when is_map(other) or is_list(other) do
    merge(%{q | values: other}, other)
  end

  def merge(q = %CQEx.Query{}, other = %{__struct__: _}) do
    merge(q, Map.delete(other, :__struct__))
  end

  def merge(q = %CQEx.Query{values: values}, other) when is_map(values) and is_list(other) do
    merge(q, Map.new(other))
  end

  def merge(q = %CQEx.Query{values: values}, other) when is_map(values) do
    %{q | values: Map.merge(values, other)}
  end

  def merge(q = %CQEx.Query{values: values}, other) when is_list(values) and is_map(other) do
    merge(q, Enum.to_list(other))
  end

  def merge(q = %CQEx.Query{values: values}, other) when is_list(values) do
    %{q | values: Keyword.merge(values, other)}
  end

  @spec new :: CQEx.Query.t()
  def new() do
    %CQEx.Query{}
  end

  @spec statement(CQEx.Query.t(), String.t()) :: CQEx.Query.t()
  def statement(q = %CQEx.Query{}, statement) do
    %{q | statement: statement}
  end

  @spec page_size(CQEx.Query.t(), integer) :: CQEx.Query.t()
  def page_size(q = %CQEx.Query{}, page_size) when is_integer(page_size) do
    %{q | page_size: page_size}
  end

  @spec consistency(CQEx.Query.t(), CQEx.consistency_values()) :: CQEx.Query.t()
  def consistency(q = %CQEx.Query{}, consistency) do
    %{q | consistency: consistency}
  end

  @spec serial_consistency(CQEx.Query.t(), CQEx.serial_consistency_values()) :: CQEx.Query.t()
  def serial_consistency(q = %CQEx.Query{}, serial_consistency) do
    %{q | serial_consistency: serial_consistency}
  end

  defp nullify(rec, fallback) when is_map(rec) do
    rec
    |> Enum.map(fn
      {key, nil} -> {key, fallback}
      {key, other} -> {key, nullify(other, fallback)}
    end)
    |> Enum.into(%{})
  end

  defp nullify(list = [{_key, _value} | _rest], fallback) do
    list
    |> Enum.map(fn
      {key, nil} -> {key, fallback}
      {key, other} -> {key, nullify(other, fallback)}
    end)
  end

  defp nullify(list = [_value | _rest], fallback) do
    list
    |> Enum.map(fn
      nil -> fallback
      other -> nullify(other, fallback)
    end)
  end

  defp nullify(nil, fallback), do: fallback
  defp nullify(other, _fallback), do: other

  defmodule Sigil do
    @moduledoc false

    @spec sigil_q(String.t(), [char()]) :: CQEx.Query.t()
    def sigil_q(statement, _modifiers) do
      %CQEx.Query{statement: statement}
    end
  end
end
