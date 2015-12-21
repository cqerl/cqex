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
end
