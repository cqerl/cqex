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

  import CQEx
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
    CQEx.cql_query(
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
  def convert(q) when Record.is_record(q, CQEx.cql_query) do
    [{:__struct__, CQEx.Query} | CQEx.cql_query(q)] |> Enum.into(%{})
  end

  def call(c, q) do
    {:ok, result} = case q do
      %CQEx.Query{} ->
        _call c, convert q
      any ->
        _call c, any
    end
    {:ok, CQEx.Result.convert result}
  end

  def cast(c, q) do
    case q do
      %CQEx.Query{} ->
        _cast c, convert q
      any ->
        _cast c, any
    end
  end
end
