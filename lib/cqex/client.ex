defmodule CQEx.Client do
  import CQEx.Helpers
  import CQEx, only: :macros

  alias :cqerl, as: CQErl

  defdelegate prepare(a),      to: CQErl, as: :prepare_client
  defdelegate prepare(a, b),   to: CQErl, as: :prepare_client

  defdelegate new,             to: CQErl, as: :new_client
  defdelegate new(a),          to: CQErl, as: :new_client
  defdelegate new(a, b),       to: CQErl, as: :new_client

  def close(client) do 
    client |> CQEx.Client.get |> CQErl.close_client
  end

  defbang new
  defbang new(a)
  defbang new(a, b)

  def get(client={p, r}) when is_pid(p) and is_reference(r), do: client
  def get(%CQEx.Result{record: cql_result(client: client)}), do: client
  def get(cql_result(client: client)), do: client
  def get(%CQEx.Result.SchemaChanged{client: client}), do: client
  def get(%CQEx.Result.Empty{client: client}), do: client
  def get(_), do: nil
end
