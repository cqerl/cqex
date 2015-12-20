defmodule CQEx.Client do
  import CQEx.Helpers

  defdelegate prepare(a),      to: :cqerl, as: :prepare_client
  defdelegate prepare(a, b),   to: :cqerl, as: :prepare_client

  defdelegate new,             to: :cqerl, as: :new_client
  defdelegate new(a),          to: :cqerl, as: :new_client
  defdelegate new(a, b),       to: :cqerl, as: :new_client

  defdelegate close(a),        to: :cqerl, as: :close_client

  defbang new
  defbang new(a)
  defbang new(a, b)
end
