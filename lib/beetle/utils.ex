defmodule Beetle.Utils do
  @moduledoc false

  def pool_name(Beetle.Backend.ETS) do
    pool_name(:single)
  end

  def pool_name(name) do
    :"beetle_backend_#{name}_pool"
  end

  # Returns Erlang Time as milliseconds since 00:00 GMT, January 1, 1970
  def timestamp do
    DateTime.utc_now() |> DateTime.to_unix(:millisecond)
  end

  # Returns tuple of {timestamp, key}, where key is {bucket_number, id}
  def stamp_key(id, scale_ms) do
    stamp = timestamp()
    # with scale_ms = 1 bucket changes every millisecond
    bucket_number = trunc(stamp / scale_ms)
    key = {bucket_number, id}
    {stamp, key}
  end
end
