# Beetle

A rate-limiter for Elixir, with pluggable storage backends.

***DISCLAIMER***
This library is a fork of an awesome and feature-complete library [Hammer](https://github.com/ExBeetle/hammer).
As of writing this text, `Hammer` doesn't have any critical issues and one should be really comfortable to use it.

Why I decided to fork:
- Hammer seems like is not beeing maintaned anymore.
- I wanted a simpler version without Elixir application (and configuration files) with additional features

Differences with `Hammer`:
- `Beetle` doesn't starts automatically. One should specify child specs in his application
- `Beetle` has decorators
- `Beetle` is faster within ETS backend
- `Beetle` is maintaned
- One could use `Hammer` backends with `Beetle`. It's backward compatible

## Installation

Beetle is [available in Hex](https://hex.pm/packages/beetle), the package can be installed
by adding `beetle` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:beetle, "~> 1.0"}]
end
```


## Documentation

On hexdocs: [https://hexdocs.pm/beetle/frontpage.html](https://hexdocs.pm/beetle/frontpage.html)

The [Tutorial](https://hexdocs.pm/beetle/tutorial.html) is an especially good place to start.

## Usage

Example:

1. Add a backend to your suppervisor:
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

2. Work with `Beetle` API:
```elixir
defmodule MyApp.VideoUpload do

  def upload(video_data, user_id) do
    case Beetle.check_rate("upload_video:#{user_id}", 60_000, 5) do
      {:allow, _count} ->
        # upload the video, somehow
      {:deny, _limit} ->
        # deny the request
    end
  end

end
```

The `Beetle` module provides the following functions:

- `check_rate(id, scale_ms, limit)`
- `check_rate_inc(id, scale_ms, limit, increment)`
- `inspect_bucket(id, scale_ms, limit)`
- `delete_buckets(id)`

Backends are configured via `Mix.Config`:

```elixir
config :beetle,
  backend: {Beetle.Backend.ETS, [expiry_ms: 60_000 * 60 * 4,
                                 cleanup_interval_ms: 60_000 * 10]}
```


See the [Tutorial](https://hexdocs.pm/beetle/tutorial.html) for more.

## Available Backends

- Beetle.Backend.ETS (provided with Beetle for testing and dev purposes, not very good for production use)
- [Hammer.Backend.Redis](https://github.com/ExHammer/hammer-backend-redis)
- [Hammer.Backend.Mnesia](https://github.com/ExHammer/hammer-backend-mnesia) (beta)

## Getting Help

If you're having trouble, either open an issue on this repo, or reach out to the maintainers on `ihorkatkov@gmail.com`


## Acknowledgements

Beetle was inspired and forked from [Hammer](https://github.com/ExBeetle/hammer)
