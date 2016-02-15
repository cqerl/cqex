defmodule CQEx do
  require Record

  Record.defrecord :cql_query, [
    statement: <<>>,
    values: [],
    reusable: nil,
    named: false,
    page_size: 100,
    page_state: nil,
    consistency: :one,
    serial_consistency: nil,
    value_encode_handler: nil
  ]

  Record.defrecord :cql_query_batch, [
    consistency: :one,
    mode: :logged,
    queries: []
  ]

  Record.defrecord :cql_schema_changed, [
    :change_type,
    :target,
    :keyspace,
    :name,
    :args
  ]

  Record.defrecord :cql_result, [
    columns: [],
    dataset: [],
    cql_query: nil,
    client: nil
  ]

  defmodule Error do
    defexception [:message, :stack]
    def exception(message) when is_bitstring(message), do: %Error{message: message}
    def exception(msg: msg, acc: acc), do: %Error{message: inspect(msg), stack: acc}
  end

  @consistencies %{
    any:            0,
    one:            1,
    two:            2,
    three:          3,
    quorum:         4,
    all:            5,
    local_quorum:   6,
    each_quorum:    7,
    serial:         8,
    local_serial:   9,
    local_one:      10
  }

  @batch_modes %{
    logged:   0,
    unlogged: 1,
    counter:  2
  }

  defmacro consistency do
    @consistencies
  end

  defmacro batch_mode do
    @batch_modes
  end
end

