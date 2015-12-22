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
  statement: "INSERT INTO animals (name, legs, friendly) values (?, ?, ?);"
}

animals_by_pair = client
|> CQEx.Query.call!("CREATE TABLE IF NOT EXISTS animals (name text PRIMARY KEY, legs tinyint, friendly boolean);")
|> CQEx.Query.call!(%{ base | values: %{name: "cat", legs: 4, friendly: false} })
|> CQEx.Query.call!(%{ base | values: %{name: "dog", legs: 4, friendly: true} })
|> CQEx.Query.call!(%{ base | values: %{name: "bonobo", legs: 2, friendly: true} })
|> CQEx.Query.call!("SELECT * FROM animals;")
|> Stream.chunk(2)

animals_by_pair
|> Enum.at(0)

# => [ %{name: "cat", legs: 4}, %{name: "dog", legs: 4} ]

animals_by_pair
|> Enum.to_list

# => [ 
#      [ %{name: "cat", legs: 4}, %{name: "dog", legs: 4} ], 
#      [ %{name: "bonobo", legs: 2} ] 
#    ]

```

Use comprehensions on the results of a CQL query

```elixir
for %{ legs: leg_count, name: name, friendly: true } <- CQEx.Query.call!(client, "SELECT * FROM animals"), 
  leg_count == 4,
  do: "#{name} has four legs"
  
# => [ "dog has four legs" ]
```

Close the client

```elixir
client |> CQEx.Client.close
```

[1]: https://github.com/matehat/cqerl/
