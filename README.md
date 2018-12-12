# cqex
Modern Cassandra driver for Elixir, using [cqerl][1] underneath.

### Installation

Add `cqex` to your application's mix.exs:

```elixir
defp deps do
  [
    # ...
    {:cqex, "~> 0.2.0"},
    # ...
  ]
end
```

And update your applications list in the project:

```elixir
def application do
  [applications: [:cqex]]
end
```

### Usage examples

If you're using a single cluster, in your project's config/config.exs:

****

```elixir
use Mix.Config

config :cqerl, 
  cassandra_nodes: [{"10.0.0.1", 9042}, {"10.0.0.2", 9042}],
  keyspace: "keyspace"
```

Then, create a transient client connection

```elixir
client = CQEx.Client.new!
```

Fetch the complete list of users, and creating a list out of it using `Enum`

```elixir
all_users = client |> CQEx.Query.call!("SELECT * FROM users;") |> Enum.to_list
# => [ list of users... ]

all_users[0]
# => %{ ... first_user ... }
```

Chain queries and using `Stream` and `Enum` to get the result set in small pages.

```elixir

alias CQEx.Query, as: Q

base = %Q{
  statement: "INSERT INTO animals (name, legs, friendly) values (?, ?, ?);",
  values: %{ legs: 4, friendly: true }
}

^base = Q.new 
|> Q.statement("INSERT INTO animals (name, legs, friendly) values (?, ?, ?);")
|> Q.put(:legs, 4)
|> Q.put(:friendly, true)

animals_by_pair = client
|> Q.call!("CREATE TABLE IF NOT EXISTS animals (name text PRIMARY KEY, legs tinyint, friendly boolean);")
|> Q.call!( base |> Q.merge(%{ name: "cat", friendly: false }) )
|> Q.call!( base |> Q.put(:name, "dog") )
|> Q.call!( base |> Q.merge(%{ name: "bonobo", legs: 2 }) )
|> Q.call!("SELECT * FROM animals;")
|> Stream.chunk(2)

animals_by_pair
|> Enum.at(0)

# => [ %{name: "cat", legs: 4, friendly: false}, %{name: "dog", legs: 4, friendly: true} ]

animals_by_pair
|> Enum.to_list

# => [ 
#      [ %{name: "cat", legs: 4, friendly: false}, %{name: "dog", legs: 4, friendly: true} ], 
#      [ %{name: "bonobo", legs: 2, friendly: true} ] 
#    ]

```

Use comprehensions on the results of a CQL query

```elixir
for %{ legs: leg_count, name: name, friendly: true } <- Q.call!(client, "SELECT * FROM animals"), 
  leg_count == 4,
  do: "#{name} has four legs"
  
# => [ "dog has four legs" ]
```

If you want different clusters, in your project's `config/config.exs`:

```elixir
use Mix.Config

config :cqerl, 
  cassandra_clusters: [
    cluster1: { [{"10.0.0.1", 9042}, {"10.0.0.2", 9042}], [keyspace: "keyspace1"] },
    cluster2: { [{"10.0.0.1", 9042}, {"10.0.0.2", 9042}], [keyspace: "keyspace2"] }
  ]
```

Then, in your code

```elixir
client = CQEx.Client.new! :cluster1
# etc
```

[1]: https://github.com/matehat/cqerl/
