defmodule Beetle.Supervisor do
  @moduledoc """
  Top-level Supervisor for the Beetle application.
  Starts a set of poolboy pools based on provided configuration,
  which are latter called to by the `Beetle` module.
  See the Application module for configuration examples.
  """

  use Supervisor

  def start_link(config, opts) do
    Supervisor.start_link(__MODULE__, config, opts)
  end

  # Single backend
  def init(backend: backend, opts: opts) do
    children = [
      to_pool_spec(:beetle_backend_single_pool, {backend, opts})
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # Private helpers
  defp to_pool_spec(name, {mod, args}) do
    pool_size = args[:pool_size] || 4
    pool_max_overflow = args[:pool_max_overflow] || 0

    opts = [
      name: {:local, name},
      worker_module: mod,
      size: pool_size,
      max_overflow: pool_max_overflow
    ]

    :poolboy.child_spec(name, opts, args)
  end
end
