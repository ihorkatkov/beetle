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

A primary goal of the Beetle project is to make it easy to implement new storage
backends. See the [documentation on creating
backends](/beetle/creatingbackends.html) for more details.
