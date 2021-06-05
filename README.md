<p align="center"><img src="logo/horizontal.png" alt="beetle" height="150px"></p>

# Beetle

A rate-limiter for Elixir, with pluggable storage backends.

[![Build Status](https://travis-ci.org/ExBeetle/beetle.svg?branch=master)](https://travis-ci.org/ExBeetle/beetle)

[![Coverage Status](https://coveralls.io/repos/github/ExBeetle/beetle/badge.svg?branch=master)](https://coveralls.io/github/ExBeetle/beetle?branch=master)


## New! Beetle-Plug

We've just released a new helper-library to make adding rate-limiting to your Phoenix
(or other plug-based) application even easier: [Beetle.Plug](https://github.com/ExBeetle/beetle-plug).



## Installation

Beetle is [available in Hex](https://hex.pm/packages/beetle), the package can be installed
by adding `beetle` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:beetle, "~> 6.0"}]
end
```


## Documentation

On hexdocs: [https://hexdocs.pm/beetle/frontpage.html](https://hexdocs.pm/beetle/frontpage.html)

The [Tutorial](https://hexdocs.pm/beetle/tutorial.html) is an especially good place to start.


## Usage

Example:

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

See the [Beetle Testbed](https://github.com/ExBeetle/beetle-testbed) app for an example of
using Beetle in a Phoenix application.


## Available Backends

- Beetle.Backend.ETS (provided with Beetle for testing and dev purposes, not very good for production use)
- [Beetle.Backend.Redis](https://github.com/ExBeetle/beetle-backend-redis)
- [Beetle.Backend.Mnesia](https://github.com/ExBeetle/beetle-backend-mnesia) (beta)

## Getting Help

If you're having trouble, either open an issue on this repo, or reach out to the maintainers ([@shanekilkelly](https://twitter.com/shanekilkelly)) on Twitter.


## Acknowledgements

Beetle was inspired by the [ExRated](https://github.com/grempe/ex_rated) library, by [grempe](https://github.com/grempe).
