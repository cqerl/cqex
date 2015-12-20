defmodule CQEx.Client do
  import CQEx.Helpers
  import CQEx, only: :macros

  defdelegate prepare(a),      to: :cqerl, as: :prepare_client
  defdelegate prepare(a, b),   to: :cqerl, as: :prepare_client

  defdelegate new,             to: :cqerl, as: :new_client
  defdelegate new(a),          to: :cqerl, as: :new_client
  defdelegate new(a, b),       to: :cqerl, as: :new_client

  defdelegate close(a),        to: :cqerl, as: :close_client

  defbang new
  defbang new(a)
  defbang new(a, b)

  def get(client={p, r}) when is_pid(p) and is_reference(r), do: client
  def get(%CQEx.Result{record: cql_result(client: client)}), do: client
  def get(%CQEx.Result.SchemaChanged{client: client}), do: client
  def get(%CQEx.Result.Empty{client: client}), do: client
  def get(_), do: nil
end
