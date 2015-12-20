defmodule CQEx do
  require Record

  records = Record.extract_all(from_lib: "cqerl/include/cqerl.hrl")

  Record.defrecord :cql_query,        Dict.get(records, :cql_query)
  Record.defrecord :cql_query_batch,  Dict.get(records, :cql_query_batch)
  Record.defrecord :cql_result,       Dict.get(records, :cql_result)

  defmodule Error, do: defstruct([msg: nil, acc: []])

  defmodule Bang do
    defexception [:message, :stack]
    def exception(message) when is_bitstring(message), do: %Bang{message: message}
    def exception(msg: msg, acc: acc), do: %Bang{message: inspect(msg), stack: acc}
  end
end

