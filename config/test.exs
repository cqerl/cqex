use Mix.Config

config :cqerl, 
  cassandra_nodes: [{"127.0.0.1", 9042}],
  keyspace: "cqex_test"
