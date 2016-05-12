defmodule CQEx.Cluster do
  import CQEx.Helpers

  defdelegate add(a),       to: :cqerl_cluster, as: :add_nodes
  defdelegate add(a, b),    to: :cqerl_cluster, as: :add_nodes
  defdelegate add(a, b, c), to: :cqerl_cluster, as: :add_nodes
end