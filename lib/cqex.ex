defmodule CQEx do
  require Record

  records = Record.extract_all from_lib: "cqerl/include/cqerl.hrl"

  Record.defrecord :cql_query,          Dict.get(records, :cql_query)
  Record.defrecord :cql_query_batch,    Dict.get(records, :cql_query_batch)
  Record.defrecord :cql_schema_changed, Dict.get(records, :cql_schema_changed)
  Record.defrecord :cql_result,         Dict.get(records, :cql_result)

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

