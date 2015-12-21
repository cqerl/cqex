# cqex
Modern Cassandra driver for Elixir

*Under development, not much documentation for now*

```elixir

client = CQEx.Client.new! {}
all_users = client |> CQEx.Query.call!("SELECT * FROM users;") |> Enum.to_list

base = %CQEx.Query{
  statement: "INSERT INTO animals (name, legs) values (?, ?);"
}

client
|> CQEx.Query.call!("CREATE TABLE animals (name text PRIMARY KEY, legs tinyint);")
|> CQEx.Query.call!(%{ base | values: %{name: "cat", legs: 4} })
|> CQEx.Query.call!(%{ base | values: %{name: "dog", legs: 4} })
|> CQEx.Query.call!(%{ base | values: %{name: "bonobo", legs: 2} })
|> CQEx.Query.call!("SELECT * FROM animals;")
|> Stream.chunks(2)
|> Enum.to_list

# => [ %{name: "cat", legs: 4}, %{name: "dog", legs: 4} ]

client |> CQEx.Client.close

```
