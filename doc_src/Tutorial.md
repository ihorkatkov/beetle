# Tutorial


## Installation

Add Beetle as a dependency in `mix.exs`:

```elixir
def deps do
  [{:beetle, "~> 1.0"}]
end
```


## Core Concepts

When we want to rate-limit some action, we want to ensure that the number of
actions permitted is limited within a specified time-period. For example, a
maximum of five times within on minute. Usually the limit is enforced per-user,
per-client, or per some other unique-ish value, such as IP address. It's much
rarer, but not unheard-of, to limit the action globally without taking the
identity of the user or client into account.

In the Beetle API, the maximum number of actions is the `limit`, and the
timespan (in milliseconds) is the `scale_ms`. The combination of the name of the
action with some unique identifier is the `id`.

Beetle uses a [Token Bucket](https://en.wikipedia.org/wiki/Token_bucket)
algorithm to count the number of actions occurring in a "bucket". If the count
within the bucket is lower than the limit, then the action is allowed, otherwise
it is denied.


## Usage

To use Beetle, you need to do two things:

- Configure the `:beetle` application
- Use the functions in the `Beetle` module

In this example, we will use the `ETS` backend, which stores data in an
in-memory ETS table.


## Configuring Beetle

The Beetle backends don't start automatically, you should define it inside your
supervisor. Like so:

```elixir
defmodule MyApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {Beetle.Backend.ETS,
       [
         ets_table_name: :hammer_backend_ets_buckets,
         expiry_ms: 60_000 * 60 * 2,
         cleanup_interval_ms: 60_000 * 2
       ]}

    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Because expiry of stale buckets is so essential to the smooth operation of a
rate-limiter, all backends will accept an `:expiry_ms` option, and many will
also accept `:cleanup_interval_ms`, depending on how expiry is implemented
internally.

(For example, Redis supports native data expiry, and so doesn't require
`:cleanup_interval_ms`.)

The `:expiry_ms` value should be configured to be longer than the life of the
longest bucket you will be using, as otherwise the bucket could be deleted while
it is still counting up hits for its time period.

The size of the backend worker pool can be tweaked with the `:pool_size` and
`:pool_max_overflow` options, (which are then supplied to `poolboy`). `:pool_size`
determines the size of the pool, and `:pool_max_overflow` determines how many extra
workers can be spawned when the system is under pressure. The default for both is `0`,
which will be fine for most systems. (Note: we've seen some weird errors sometimes when using a `:pool_max_overflow` higher than zero. Always check how this works for you in production, and consider setting a higher `:pool_size` instead).

Luckily, even if you don't configure `:beetle` at all, the application will
default to the ETS backend anyway, with some sensible defaults.


## The Beetle Module

All you need to do is use the various functions in the `Beetle` module:

- `check_rate(id::string, scale_ms::integer, limit::integer)`
- `check_rate_inc(id::string, scale_ms::integer, limit::integer, increment::integer)`
- `inspect_bucket(id::string, scale_ms::integer, limit::integer)`
- `delete_buckets(id::string)`
- `make_rate_checker(id_prefix, scale_ms, limit)`

The most interesting is `check_rate`, which checks if the rate-limit for the
given `id` has been exceeded in the specified time-`scale`.

Ideally, the `id` should be a combination of some action-specific, descriptive
prefix with some data which uniquely identifies the user or client performing
the action.

Example:

```elixir
# limit file uploads to 10 per minute per user
user_id = get_user_id_somehow()
case Beetle.check_rate("upload_file:#{user_id}", 60_000, 10) do
  {:allow, _count} ->
    # upload the file
  {:deny, _limit} ->
    # deny the request
end
```


## Custom increments

The `Beetle` module also includes  a `check_rate_inc` function, which allows you
to specify the number by which to increment the current bucket. This is useful
for rate-limiting APIs which have some idea of "cost", where the cost of a given
operation can be determined and expressed as an integer.

Example:

```elixir
# Bulk file upload
user_id = get_user_id_somehow()
n = get_number_of_files()
case Beetle.check_rate_inc("upload_file_bulk:#{user_id}", 60_000, 10, n) do
  {:allow, _count} ->
    # upload all of the files
  {:deny, _limit} ->
    # deny the request
end
```


## Switching to Redis

There may come a time when ETS just doesn't cut it, for example if we end up
load-balancing across many nodes and want to keep our rate-limiter state in one
central store. [Redis](https://redis.io) is ideal for this use-case, and
fortunately Beetle supports
a [Redis backend](https://github.com/ExBeetle/hammer-backend-redis).

To change our application to use the Redis backend, we need to install the
redis backend package and change function arguments.

```elixir
defmodule MyApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {Hammer.Backend.Redis,
      [
        expiry_ms: 60_000 * 60 * 2,
        redix_config: [host: "localhost", port: 6379],
        pool_size: 4,
        pool_max_overflow: 2
      ]}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

Beetle.check_rate(Hammer.Backend.Redis, "upload:#{user_id}", 60_000, 5)
```

## (Advanced) using multiple backends at the same time

Beetle can be configured to start multiple backends, which can then be referred
to separately when checking a rate-limit. In this example we configure both and
ETS backend and Redis backend

We can then refer to these backends separately:

```elixir
Beetle.check_rate(Beetle.Backend.ETS,   "upload:#{user_id}", 60_000, 5)
Beetle.check_rate(Hammer.Backend.Redis, "upload:#{user_id}", 60_000, 5)
```

When using multiple backends the backend specifier key is mandatory, there is no
notion of a default backend.

## Further Reading

See the docs for the [Beetle](/beetle/Beetle.html) module for full documentation
on all the functions created by `use Beetle`.

See the [Beetle.Application](/beetle/Beetle.Application.html) for all
configuration options.

Also, consult the documentation for the backend you are using, for any extra
configuration options that may be relevant.

See the [Creating Backends](/beetle/creatingbackends.html) for information on
creating new backends for Beetle.
