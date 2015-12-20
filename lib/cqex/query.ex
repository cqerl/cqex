defmodule CQEx.Query do
  import CQEx.Helpers

  defdelegate call(a, b),             to: :cqerl, as: :run_query
  defdelegate cast(a, b),             to: :cqerl, as: :send_query
  defdelegate has_more_pages(a),      to: :cqerl
  defdelegate fetch_more(a),          to: :cqerl
  defdelegate fetch_more_async(a),    to: :cqerl

  defbang call(a, b)
  defbang fetch_more(a)
end
