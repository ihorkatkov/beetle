# Beetle, a Rate-Limiter for Elixir

Beetle is a rate-limiter for the [Elixir](https://elixir-lang.org/) language.
It's killer feature is a pluggable backend system, allowing you to use whichever
storage suits your needs. Currently, backends for ETS,
[Redis](https://github.com/ExBeetle/beetle-backend-redis), and [Mnesia](https://github.com/ExBeetle/beetle-backend-mnesia) are available.


```elixir
    case Beetle.check_rate("file_upload:#{user_id}", 60_000, 10) do
      {:allow, _count} ->
        Upload.file(data)
      {:deny, _limit} ->
        render_error_page()
    end
```

To get started with Beetle, read the [Tutorial](/beetle/tutorial.html).

See the [Beetle.Application module](/beetle/Beetle.Application.html) for full
documentation of configuration options.

A primary goal of the Beetle project is to make it easy to implement new storage
backends. See the [documentation on creating
backends](/beetle/creatingbackends.html) for more details.

## New! Beetle-Plug

We've just released a new helper-library to make adding rate-limiting to your Phoenix
(or other plug-based) application even easier: [Beetle.Plug](https://github.com/ExBeetle/beetle-plug).
