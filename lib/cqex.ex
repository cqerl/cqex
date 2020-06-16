defmodule CQEx do
  @moduledoc false

  require Record

  @type consistency_values ::
          :all
          | :any
          | :each_quorum
          | :local_one
          | :local_quorum
          | :one
          | :quorum
          | :three
          | :two
          | 0
          | 1
          | 2
          | 3
          | 4
          | 5
          | 6
          | 7
          | 10

  @type serial_consistency_values ::
          :local_serial
          | :serial
          | :undefined
          | 8
          | 9

  @type batch_mode_values ::
          :counter
          | :logged
          | :unlogged
          | 0
          | 1
          | 2

  Record.defrecord(:cql_query,
    statement: <<>>,
    values: [],
    reusable: nil,
    named: false,
    page_size: 100,
    page_state: nil,
    consistency: :one,
    serial_consistency: nil,
    value_encode_handler: nil
  )

  @type cql_query ::
          {:cql_query, iodata(), Keyword.t() | map(), boolean | :undefined, boolean, integer,
           :undefined | binary, consistency_values(), serial_consistency_values(),
           :undefined | fun}

  Record.defrecord(:cql_query_batch,
    consistency: :one,
    mode: :logged,
    queries: []
  )

  @type cql_query_batch ::
          {:cql_query_batch, consistency_values(), batch_mode_values(), [cql_query]}

  Record.defrecord(:cql_schema_changed, [
    :change_type,
    :target,
    :keyspace,
    :name,
    :args
  ])

  @type cql_schema_changed :: {:cql_schema_change, any, any, any, any, any}

  Record.defrecord(:cql_result,
    columns: [],
    dataset: [],
    cql_query: nil,
    client: nil
  )

  @type cql_result :: {:cql_result, any, any, any, any}

  defmodule Error do
    defexception [:message, :stack]
    def exception(message) when is_bitstring(message), do: %Error{message: message}
    def exception(msg: msg, acc: acc), do: %Error{message: inspect(msg), stack: acc}
  end

  defmacro consistency do
    %{
      any: 0,
      one: 1,
      two: 2,
      three: 3,
      quorum: 4,
      all: 5,
      local_quorum: 6,
      each_quorum: 7,
      serial: 8,
      local_serial: 9,
      local_one: 10
    }
  end

  defmacro batch_mode do
    %{
      logged: 0,
      unlogged: 1,
      counter: 2
    }
  end
end
