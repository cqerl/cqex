# cqex
Modern Cassandra driver for Elixir, using [cqerl][1] underneath.

*Under development, so not much documentation for now*

### Usage examples

Create a transient client connection

```elixir
client = CQEx.Client.new! {}
```

Fetch the complete list of users, and creating a list out of it using `Enum`

```elixir
all_users = client |> CQEx.Query.call!("SELECT * FROM users;") |> Enum.to_list
# => [ list of users... ]
```

Chain queries and using `Stream` and `Enum` to get the result set in small pages.

```elixir
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
```

Close the client

```elixir
client |> CQEx.Client.close
```

[1]: https://github.com/matehat/cqerl/
