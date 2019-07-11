defmodule CQEx.Result do
  import CQEx, only: :macros

  alias CQEx.Result, as: Result
  alias :cqerl, as: CQErl

  require Record

  defstruct record: nil, auto_fetch_more: true

  @type t() :: %__MODULE__{
          record: CQEx.cql_result() | nil,
          auto_fetch_more: boolean()
        }

  defmacro __using__(_opts) do
    quote do
      alias CQEx.Result, as: R
    end
  end

  defmodule SchemaChanged do
    @moduledoc false

    defstruct change_type: nil,
              target: nil,
              keyspace: nil,
              name: nil,
              args: nil,
              client: nil

    @type t() :: %__MODULE__{
            change_type: atom(),
            target: atom(),
            keyspace: String.t(),
            name: String.t(),
            args: [String.t()],
            client: :cqerl.client() | nil
          }
  end

  defmodule Empty do
    @moduledoc false

    defstruct client: nil

    @type t() :: %__MODULE__{
            client: :cqerl.client() | nil
          }
  end

  @spec(
    convert(CQEx.cql_result(), :cqerl.client() | nil) :: Result.t(),
    convert(CQEx.cql_schema_changed(), :cqerl.client() | nil) :: Result.SchemaChanged.t(),
    convert(:void, :cqerl.client() | nil) :: Result.Empty.t()
  )
  def convert(r, _client) when Record.is_record(r, :cql_result) do
    %Result{record: r}
  end

  def convert(q, client) when Record.is_record(q, :cql_schema_changed) do
    props = [{:__struct__, CQEx.Result.SchemaChanged}, {:client, client}] ++ cql_schema_changed(q)
    Enum.into(props, %{})
  end

  def convert(:void, client), do: %Result.Empty{client: client}

  @spec size(CQEx.cql_result() | CQEx.Result.t()) :: non_neg_integer
  def size(%Result{record: rec}), do: CQErl.size(rec)
  def size(rec), do: CQErl.size(rec)

  @spec head(CQEx.cql_result() | CQEx.Result.t()) :: Keyword.t() | map()
  def head(%Result{record: rec}), do: nillify(CQErl.head(rec))
  def head(rec), do: nillify(CQErl.head(rec))

  @spec head(CQEx.cql_result() | CQEx.Result.t(), Keyword.t()) :: Keyword.t() | map()
  def head(%Result{record: rec}, opts), do: nillify(CQErl.head(rec, opts))
  def head(rec, opts), do: nillify(CQErl.head(rec, opts))

  @spec tail(CQEx.cql_result() | CQEx.Result.t()) ::
          CQEx.cql_result() | CQEx.Result.t() | Result.Empty.t()
  def tail(%Result{record: rec}), do: tail(rec)

  def tail(rec) do
    %Result{record: CQErl.tail(rec)}
  end

  @spec next(CQEx.cql_result() | CQEx.Result.t()) ::
          :empty_dataset | {Keyword.t() | map(), CQEx.Result.t()}
  def next(%Result{record: rec}), do: next(rec)

  def next(rec) do
    case CQErl.next(rec) do
      {head, tail} ->
        {nillify(head), %Result{record: tail}}

      empty_dataset ->
        empty_dataset
    end
  end

  @spec all_rows(CQEx.cql_result() | CQEx.Result.t(), Keyword.t()) :: [Keyword.t() | map()]
  def all_rows(%Result{record: rec}, opts) do
    CQErl.all_rows(rec, opts) |> Enum.map(&nillify(&1))
  end

  def all_rows(rec, opts) do
    CQErl.all_rows(rec, opts) |> Enum.map(&nillify(&1))
  end

  @spec all_rows(CQEx.cql_result() | CQEx.Result.t()) :: [Keyword.t() | map()]
  def all_rows(%Result{record: rec}) do
    CQErl.all_rows(rec) |> Enum.map(&nillify(&1))
  end

  def all_rows(rec) do
    CQErl.all_rows(rec) |> Enum.map(&nillify(&1))
  end

  @spec has_more_pages?(CQEx.cql_result() | CQEx.Result.t()) :: boolean
  def has_more_pages?(%Result{record: rec}), do: CQErl.has_more_pages(rec)
  def has_more_pages?(rec), do: CQErl.has_more_pages(rec)

  @spec fetch_more(CQEx.cql_result() | CQEx.Result.t()) :: {:ok, CQEx.Result.t()}
  def fetch_more(%Result{record: rec}), do: fetch_more(rec)

  def fetch_more(rec) do
    {:ok, rec} = CQErl.fetch_more(rec)
    {:ok, %Result{record: rec}}
  end

  @spec fetch_more!(CQEx.cql_result() | CQEx.Result.t()) :: CQEx.Result.t()
  def fetch_more!(a) do
    case fetch_more(a) do
      {:ok, result} ->
        result
    end
  end

  @spec fetch_more_async(CQEx.cql_result() | CQEx.Result.t()) :: reference()
  def fetch_more_async(%Result{record: rec}), do: fetch_more_async(rec)

  def fetch_more_async(result) do
    current = self()

    spawn_link(fn ->
      tag = CQErl.fetch_more_async(result)
      send(current, {:tag, tag})

      receive do
        {:result, ^tag, result} ->
          send(current, {:result, tag, CQEx.Result.convert(result, nil)})

        any ->
          send(current, any)
      end
    end)

    receive do
      {:tag, tag} -> tag
    end
  end

  defp nillify(rec) when is_map(rec) do
    rec
    |> Enum.map(fn
      {key, :undefined} -> {key, nil}
      {key, :null} -> {key, nil}
      {key, other} -> {key, nillify(other)}
    end)
    |> Enum.into(%{})
  end

  defp nillify(list = [{_key, _value} | _rest]) do
    list
    |> Enum.map(fn
      {key, :undefined} -> {key, nil}
      {key, :null} -> {key, nil}
      {key, other} -> {key, nillify(other)}
    end)
  end

  defp nillify(list = [_value | _rest]) do
    list
    |> Enum.map(fn
      :undefined -> nil
      :null -> nil
      other -> other
    end)
  end

  defp nillify(:undefined), do: nil
  defp nillify(:null), do: nil
  defp nillify(other), do: other

  def fetch(result, index) do
    case Enum.at(result, index) do
      nil -> :error
      row -> {:ok, row}
    end
  end

  defimpl Enumerable do
    alias CQEx.Result, as: R

    @impl true
    def count(result) do
      {:ok, R.size(result)}
    end

    @impl true
    def slice(_result) do
      {:error, __MODULE__}
    end

    @impl true
    def member?(result, row) do
      {:ok, find(R.next(result), row)}
    end

    @impl true
    def reduce(cursor, acc, reducer)

    def reduce(_result, {:halt, acc}, _fun) do
      {:halted, acc}
    end

    def reduce(result, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(result, &1, fun)}
    end

    def reduce(result, {:cont, acc}, fun) do
      case R.size(result) do
        0 ->
          case result.auto_fetch_more do
            false -> {:done, acc}
            true -> maybe_fetch_and_continue(result, acc, fun)
          end

        _n ->
          {h, t} = R.next(result)
          reduce(t, fun.(h, acc), fun)
      end
    end

    defp maybe_fetch_and_continue(result, acc, fun) do
      case R.has_more_pages?(result) do
        true ->
          next_page = R.fetch_more!(result)

          case R.next(next_page) do
            {h, t} -> reduce(t, fun.(h, acc), fun)
            :empty_dataset -> {:done, acc}
          end

        false ->
          {:done, acc}
      end
    end

    defp find(:empty_dataset, _row), do: false
    defp find({row2, _tail}, row) when row == row2, do: true

    defp find({_, tail}, row) do
      member?(tail, row)
    end
  end
end

defimpl Enumerable, for: CQEx.Result.Empty do
  @impl true
  def count(_result) do
    {:ok, 0}
  end

  @impl true
  def member?(_result, _row) do
    {:ok, false}
  end

  @impl true
  def reduce(_result, {_, acc}, _fun) do
    {:done, acc}
  end

  @impl true
  def slice(_result) do
    {:error, __MODULE__}
  end
end
