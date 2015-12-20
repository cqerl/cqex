defmodule CQEx.Result do
  defdelegate size(a),        to: :cqerl
  defdelegate head(a),        to: :cqerl
  defdelegate head(a, b),     to: :cqerl
  defdelegate tail(a),        to: :cqerl
  defdelegate next(a),        to: :cqerl
  defdelegate all_rows(a),    to: :cqerl
  defdelegate all_rows(a, b), to: :cqerl
end
