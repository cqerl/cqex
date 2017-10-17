defmodule CQEx.Client do
  import CQEx.Helpers
  import CQEx, only: :macros

  defdelegate new,             to: :cqerl, as: :get_client
  defdelegate new(a),          to: :cqerl, as: :get_client
  defdelegate new(a, b),       to: :cqerl, as: :get_client

  def close(client) do
    client
    |> CQEx.Client.get()
    |> :cqerl.close_client()
  end

  defbang new
  defbang new(a)
  defbang new(a, b)

  def get(client={p, r}) when is_pid(p) and is_reference(r) do
    client
  end
  def get(%CQEx.Result{record: cql_result(client: client)}) do
    client
  end
  def get(cql_result(client: client)) do
    client
  end
  def get(%CQEx.Result.SchemaChanged{client: client}) do
    client
  end
  def get(%CQEx.Result.Empty{client: client}) do
    client
  end
  def get(_) do
    nil
  end
end
