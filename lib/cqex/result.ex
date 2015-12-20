defmodule CQEx.Result do
  import CQEx.Helpers
  import CQEx, only: :macros

  require Record

  defstruct record: nil
  alias CQEx.Result, as: Result

  defdelegate _size(a),               to: :cqerl, as: :size
  defdelegate _head(a),               to: :cqerl, as: :head
  defdelegate _head(a, b),            to: :cqerl, as: :head
  defdelegate _tail(a),               to: :cqerl, as: :tail
  defdelegate _next(a),               to: :cqerl, as: :next
  defdelegate _all_rows(a),           to: :cqerl, as: :all_rows
  defdelegate _all_rows(a, b),        to: :cqerl, as: :all_rows
  defdelegate _has_more_pages(a),     to: :cqerl, as: :has_more_pages
  defdelegate _fetch_more(a),         to: :cqerl, as: :fetch_more
  defdelegate _fetch_more_async(a),   to: :cqerl, as: :fetch_more_async

  defmodule SchemaChanged do
    defstruct [
      change_type: nil,
      target: nil,
      keyspace: nil,
      name: nil,
      args: nil,
      client: nil
    ]
  end

  defmodule Empty do
    defstruct [client: nil]
  end

  defbang fetch_more(a)

  def convert(r, _client) when Record.is_record(r, cql_result) do
    %Result{record: r}
  end
  def convert(q, client) when Record.is_record(q, cql_schema_changed) do
    props = [{:__struct__, CQEx.Result.SchemaChanged}, {:client, client}] ++ cql_schema_changed(q)
    Enum.into props, %{}
  end
  def convert(:void, client), do: %Result.Empty{client: client}
  def convert(res, _), do: res

  def convert(%Result{:record => record}), do: record

  def size(%Result{record: rec}), do: _size rec
  def size(rec), do: _size rec

  def head(%Result{record: rec}), do: _head rec
  def head(rec), do: _head rec

  def head(%Result{record: rec}, Opts), do: _head rec, Opts
  def head(rec, Opts), do: _head rec, Opts

  def tail(%Result{record: rec}), do: tail rec
  def tail(rec) do
    %Result{record: _tail rec}
  end

  def next(%Result{record: rec}), do: next rec
  def next(rec) do
    case _next(rec) do
      {head, tail} ->
        {head, %Result{record: tail}}
      empty_dataset -> empty_dataset
    end
  end

  def all_rows(%Result{record: rec}, Opts), do: _all_rows rec, Opts
  def all_rows(rec, Opts), do: _all_rows rec, Opts

  def all_rows(%Result{record: rec}), do: _all_rows rec
  def all_rows(rec), do: _all_rows rec

  def has_more_pages(%Result{record: rec}), do: _has_more_pages rec
  def has_more_pages(rec), do: _has_more_pages rec

  def fetch_more(%Result{record: rec}), do: fetch_more rec
  def fetch_more(rec) do
    {:ok, rec} = _fetch_more rec
    {:ok, %Result{record: rec}}
  end

  def fetch_more_async(%Result{record: rec}), do: _fetch_more_async rec
  def fetch_more_async(rec), do: _fetch_more_async rec

  defimpl Enumerable do
    alias CQEx.Result, as: R

    def count(result) do
      {:ok, R.size(result)}
    end

    def member?(result, row) do
      {:ok, find(R.next(result), row)}
    end

    def reduce(cursor, acc, reducer)
    def reduce(_result, {:halt, acc}, _fun) do
      {:halted, acc}
    end
    def reduce(result,  {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(result, &1, fun)}
    end
    def reduce(result,  {:cont, acc}, fun) do
      case R.size(result) do
        0 ->
          case R.has_more_pages(result) do
            true ->
              next_page = result |> R.fetch_more!
              case R.next(next_page) do
                {h, t} -> reduce t, fun.(h, acc), fun
                :empty_dataset -> {:done, acc}
              end
            false ->
              {:done, acc}
          end
        n ->
          {h, t} = R.next result
          reduce t, fun.(h, acc), fun
      end
    end

    defp find(:empty_dataset, row), do: false
    defp find({row, tail}, row), do: true
    defp find({_, tail}, row) do
      member? tail, row
    end
  end

end
