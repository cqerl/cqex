defmodule CQEx.Query do

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

  import CQEx, only: :macros
  import CQEx.Helpers
  require Record

  defdelegate _call(a, b),            to: :cqerl, as: :run_query
  defdelegate _cast(a, b),            to: :cqerl, as: :send_query

  defbang call(a, b)

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
      values: values,
      reusable: reusable,
      named: named,
      page_size: page_size,
      page_state: page_state,
      consistency: consistency,
      serial_consistency: serial_consistency,
      value_encode_handler: value_encode_handler
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
        _call client, convert q
      any ->
        _call client, any
    end
    {:ok, CQEx.Result.convert(result, client)}
  end

  def cast(c, q) do
    client = CQEx.Client.get c
    current = self()

    spawn_link fn ->
      tag = case q do
        %CQEx.Query{} ->
          _cast client, convert q
        any ->
          _cast client, any
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
end
