defmodule BeetleTest do
  use ExUnit.Case, async: false

  setup _context do
    config =
      {Beetle.Backend.ETS,
       [
         ets_table_name: :hammer_backend_ets_buckets,
         expiry_ms: 60_000 * 60 * 2,
         cleanup_interval_ms: 60_000 * 2
       ]}

    {:ok, _pid} = start_supervised(config)

    pool = Beetle.Utils.pool_name()

    opts = [
      name: {:local, pool},
      worker_module: Beetle.Backend.ETS,
      size: 4,
      max_overflow: 4
    ]

    worker_args = [
      expiry_ms: 5001,
      cleanup_interval_ms: 6002
    ]

    {:ok, _pid} = :poolboy.start_link(opts, worker_args)
    {:ok, [pool: pool]}
  end

  test "make_rate_checker" do
    check = Beetle.make_rate_checker("some-prefix:", 10000, 2)
    assert {:allow, 1} = check.("aaa")
    assert {:allow, 2} = check.("aaa")
    assert {:deny, 2} = check.("aaa")
    assert {:deny, 2} = check.("aaa")
    assert {:allow, 1} = check.("bbb")
    assert {:allow, 2} = check.("bbb")
    assert {:deny, 2} = check.("bbb")
    assert {:deny, 2} = check.("bbb")
  end

  test "returns {:ok, 1} tuple on first access" do
    assert {:allow, 1} = Beetle.check_rate("my-bucket", 10_000, 10)
  end

  test "returns {:ok, 4} tuple on in-limit checks" do
    assert {:allow, 1} = Beetle.check_rate("my-bucket", 10_000, 10)
    assert {:allow, 2} = Beetle.check_rate("my-bucket", 10_000, 10)
    assert {:allow, 3} = Beetle.check_rate("my-bucket", 10_000, 10)
    assert {:allow, 4} = Beetle.check_rate("my-bucket", 10_000, 10)
  end

  test "returns expected tuples on mix of in-limit and out-of-limit checks" do
    assert {:allow, 1} = Beetle.check_rate("my-bucket", 10_000, 2)
    assert {:allow, 2} = Beetle.check_rate("my-bucket", 10_000, 2)
    assert {:deny, 2} = Beetle.check_rate("my-bucket", 10_000, 2)
    assert {:deny, 2} = Beetle.check_rate("my-bucket", 10_000, 2)
  end

  test "returns expected tuples on 1000ms bucket check with a sleep in the middle" do
    assert {:allow, 1} = Beetle.check_rate("my-bucket", 1000, 2)
    assert {:allow, 2} = Beetle.check_rate("my-bucket", 1000, 2)
    assert {:deny, 2} = Beetle.check_rate("my-bucket", 1000, 2)
    :timer.sleep(1001)
    assert {:allow, 1} = Beetle.check_rate("my-bucket", 1000, 2)
    assert {:allow, 2} = Beetle.check_rate("my-bucket", 1000, 2)
    assert {:deny, 2} = Beetle.check_rate("my-bucket", 1000, 2)
  end

  test "returns expected tuples on inspect_bucket" do
    assert {:ok, {0, 2, _, nil, nil}} = Beetle.inspect_bucket("my-bucket1", 1000, 2)
    assert {:allow, 1} = Beetle.check_rate("my-bucket1", 1000, 2)
    assert {:ok, {1, 1, _, _, _}} = Beetle.inspect_bucket("my-bucket1", 1000, 2)
    assert {:allow, 2} = Beetle.check_rate("my-bucket1", 1000, 2)
    assert {:allow, 1} = Beetle.check_rate("my-bucket2", 1000, 2)
    assert {:ok, {2, 0, _, _, _}} = Beetle.inspect_bucket("my-bucket1", 1000, 2)
    assert {:deny, 2} = Beetle.check_rate("my-bucket1", 1000, 2)
    assert {:ok, {3, 0, ms_to_next_bucket, _, _}} = Beetle.inspect_bucket("my-bucket1", 1000, 2)
    assert ms_to_next_bucket < 1000
  end

  test "returns expected tuples on delete_buckets" do
    assert {:allow, 1} = Beetle.check_rate("my-bucket1", 1000, 2)
    assert {:allow, 2} = Beetle.check_rate("my-bucket1", 1000, 2)
    assert {:deny, 2} = Beetle.check_rate("my-bucket1", 1000, 2)
    assert {:allow, 1} = Beetle.check_rate("my-bucket2", 1000, 2)
    assert {:allow, 2} = Beetle.check_rate("my-bucket2", 1000, 2)
    assert {:deny, 2} = Beetle.check_rate("my-bucket2", 1000, 2)
    assert {:ok, 1} = Beetle.delete_buckets("my-bucket1")
    assert {:allow, 1} = Beetle.check_rate("my-bucket1", 1000, 2)
    assert {:deny, 2} = Beetle.check_rate("my-bucket2", 1000, 2)

    assert {:ok, 0} = Beetle.delete_buckets("unknown-bucket")
  end

  test "count_hit_inc" do
    assert {:allow, 4} = Beetle.check_rate_inc("cost-bucket1", 1000, 10, 4)
    assert {:allow, 9} = Beetle.check_rate_inc("cost-bucket1", 1000, 10, 5)
    assert {:deny, 10} = Beetle.check_rate_inc("cost-bucket1", 1000, 10, 3)
  end

  test "mixing count_hit with count_hit_inc" do
    assert {:allow, 3} = Beetle.check_rate_inc("cost-bucket2", 1000, 10, 3)
    assert {:allow, 4} = Beetle.check_rate("cost-bucket2", 1000, 10)
    assert {:allow, 5} = Beetle.check_rate("cost-bucket2", 1000, 10)
    assert {:allow, 9} = Beetle.check_rate_inc("cost-bucket2", 1000, 10, 4)
    assert {:allow, 10} = Beetle.check_rate("cost-bucket2", 1000, 10)
    assert {:deny, 10} = Beetle.check_rate_inc("cost-bucket2", 1000, 10, 2)
  end
end
