defmodule ETSTest do
  use ExUnit.Case

  alias Beetle.Backend

  setup _context do
    opts = [expiry_ms: 5, cleanup_interval_ms: 2, ets_table_name: :test_beetle_table]
    {:ok, beetle_ets_pid} = Backend.ETS.start_link(opts)
    {:ok, Keyword.put(opts, :pid, beetle_ets_pid)}
  end

  test "count_hit", context do
    pid = context[:pid]
    {stamp, key} = Beetle.Utils.stamp_key("one", 200_000)
    assert {:ok, 1} = Backend.ETS.count_hit(pid, key, stamp)
    assert {:ok, 2} = Backend.ETS.count_hit(pid, key, stamp)
    assert {:ok, 3} = Backend.ETS.count_hit(pid, key, stamp)
  end

  test "get_bucket", context do
    pid = context[:pid]
    {stamp, key} = Beetle.Utils.stamp_key("two", 200_000)
    # With no hits
    assert {:ok, nil} = Backend.ETS.get_bucket(pid, key)
    # With one hit
    assert {:ok, 1} = Backend.ETS.count_hit(pid, key, stamp)
    assert {:ok, {{_, "two"}, 1, _, _}} = Backend.ETS.get_bucket(pid, key)
    # With two hits
    assert {:ok, 2} = Backend.ETS.count_hit(pid, key, stamp)
    assert {:ok, {{_, "two"}, 2, _, _}} = Backend.ETS.get_bucket(pid, key)
  end

  test "delete_buckets", context do
    pid = context[:pid]
    {stamp, key} = Beetle.Utils.stamp_key("three", 200_000)
    # With no hits
    assert {:ok, 0} = Backend.ETS.delete_buckets(pid, "three")
    # With three hits in same bucket
    assert {:ok, 1} = Backend.ETS.count_hit(pid, key, stamp)
    assert {:ok, 2} = Backend.ETS.count_hit(pid, key, stamp)
    assert {:ok, 3} = Backend.ETS.count_hit(pid, key, stamp)
    assert {:ok, 1} = Backend.ETS.delete_buckets(pid, "three")
  end

  test "timeout pruning", context do
    pid = context[:pid]
    expiry_ms = context[:expiry_ms]
    {stamp, key} = Beetle.Utils.stamp_key("one", 200_000)
    assert {:ok, 1} = Backend.ETS.count_hit(pid, key, stamp)
    assert {:ok, {{_, "one"}, 1, _, _}} = Backend.ETS.get_bucket(pid, key)
    :timer.sleep(expiry_ms * 2)
    assert {:ok, nil} = Backend.ETS.get_bucket(pid, key)
  end
end
