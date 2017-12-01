defmodule CQExTest do

  alias CQEx.Query, as: Q
  use ExUnit.Case
  doctest CQEx, async: false, seed: 0

  setup_all do
    client = CQEx.Client.new!
    [client: client]
  end

  test "Create simple table", %{client: client} do
    client
    |> Q.call!("DROP TABLE IF EXISTS test_table")
    |> Q.call!("CREATE TABLE test_table ( test_ascii ascii, test_blob blob,
                test_decimal decimal, test_float float, test_inet inet, test_timestamp timestamp,
                test_varchar varchar, test_bigint bigint, test_boolean boolean, test_double double,
                test_int int, test_timeuuid timeuuid, test_uuid uuid, test_varint varint, test_tinyint tinyint,
                test_text text, test_date date, test_smallint smallint, test_time time,
                test_list list<text>, test_set set<text>, test_map map<text, text>, 
                PRIMARY KEY( (test_text), test_uuid ) )")
    :timer.sleep 800
  end

  test "Drop table", %{client: client} do
    client
    |> Q.call!("DROP TABLE test_table")
  end

end
