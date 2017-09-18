defmodule CQEx.Result do
  import CQEx.Helpers
  import CQEx, only: :macros

  require Record

  defstruct [ record: nil, auto_fetch_more: true ]

  defmacro __using__(_opts) do
    quote do
      alias CQEx.Result, as: R
    end
  end

  alias CQEx.Result, as: Result
  alias :cqerl, as: CQErl

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

  def convert(r, _client) when Record.is_record(r, :cql_result) do
    %Result{record: r}
  end
  def convert(q, client) when Record.is_record(q, :cql_schema_changed) do
    props = [{:__struct__, CQEx.Result.SchemaChanged}, {:client, client}] ++ cql_schema_changed(q)
    Enum.into props, %{}
  end
  def convert(:void, client), do: %Result.Empty{client: client}

  def size(%Result{record: rec}), do: CQErl.size rec
  def size(rec), do: CQErl.size rec

  def head(%Result{record: rec}), do: CQErl.head rec
  def head(rec), do: CQErl.head rec

  def head(%Result{record: rec}, opts), do: nillify CQErl.head rec, opts
  def head(rec, opts), do: nillify CQErl.head rec, opts

  def tail(%Result{record: rec}), do: tail rec
  def tail(rec) do
    %Result{record: CQErl.tail rec}
  end

  def next(%Result{record: rec}), do: next rec
  def next(rec) do
    case CQErl.next(rec) do
      {head, tail} ->
        {nillify(head), %Result{record: tail}}
      empty_dataset -> empty_dataset
    end
  end

  def all_rows(%Result{record: rec}, opts) do
    CQErl.all_rows(rec, opts) |> Enum.map(&(nillify(&1)))
  end
  def all_rows(rec, opts) do
    CQErl.all_rows(rec, opts) |> Enum.map(&(nillify(&1)))
  end

  def all_rows(%Result{record: rec}) do
    CQErl.all_rows(rec) |> Enum.map(&(nillify(&1)))
  end
  def all_rows(rec) do
    CQErl.all_rows(rec) |> Enum.map(&(nillify(&1)))
  end

  def has_more_pages?(%Result{record: rec}), do: CQErl.has_more_pages rec
  def has_more_pages?(rec), do: CQErl.has_more_pages rec

  def fetch_more(%Result{record: rec}), do: fetch_more rec
  def fetch_more(rec) do
    {:ok, rec} = CQErl.fetch_more rec
    {:ok, %Result{record: rec}}
  end

  def fetch_more_async(%Result{record: rec}), do: fetch_more_async rec
  def fetch_more_async(result) do
    current = self()

    spawn_link fn ->
      tag = CQErl.fetch_more_async result
      send current, {:tag, tag}

      receive do
        {:result, ^tag, result} ->
          send current, {:result, tag, CQEx.Result.convert(result, nil)}
        any ->
          send current, any
      end
    end

    receive do
      {:tag, tag} -> tag
    end
  end

  defp nillify(rec) when is_map(rec) do
    rec
    |> Enum.map(fn
      {key, :null} -> {key, nil};
      {key, other} -> {key, nillify(other)}
    end)
    |> Enum.into(%{})
  end
  defp nillify(list = [{_key, _value} | _rest]) do
    list
    |> Enum.map(fn
      {key, :null} -> {key, nil};
      {key, other} -> {key, nillify(other)}
    end)
  end
  defp nillify(list = [_value | _rest]) do
    list
    |> Enum.map(fn
      :null -> nil;
      other -> other
    end)
  end
  defp nillify(:null), do: nil
  defp nillify(other), do: other

  def fetch(result, index) do
    case Enum.at(result, index) do
      nil -> :error;
      row -> { :ok, row }
    end
  end

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
          case result.auto_fetch_more do
            false -> {:done, acc}
            true -> maybe_fetch_and_continue result, acc, fun
          end

        _n ->
          {h, t} = R.next result
          reduce t, fun.(h, acc), fun
      end
    end

    defp maybe_fetch_and_continue(result, acc, fun) do
      case R.has_more_pages?(result) do
        true ->
          next_page = result |> R.fetch_more!
          case R.next(next_page) do
            {h, t} -> reduce t, fun.(h, acc), fun
            :empty_dataset -> {:done, acc}
          end
        false ->
          {:done, acc}
      end
    end

    defp find(:empty_dataset, _row), do: false
    defp find({row2, _tail}, row) when row == row2, do: true
    defp find({_, tail}, row) do
      member? tail, row
    end
  end

end

defimpl Enumerable, for: CQEx.Result.Empty do
  def count(_result) do
    {:ok, 0}
  end
  def member?(_result, _row) do
    {:ok, false}
  end
  def reduce(_result, {_, acc}, _fun) do
    {:done, acc}
  end
end
