defmodule Hf.Metrics do
  import Hf.LocalLogger

  def new(_, _) do
    :ok
  end

  def delete(_name) do
    :ok
  end

  def delete(_name, _value) do
    :ok
  end

  @spec increment_counter(any()) :: :ok | {:error, term()}
  def increment_counter(name) do
    increment_counter(name, 1)
  end

  @spec increment_counter(any(), pos_integer()) :: :ok | {:error, term()}
  def increment_counter(name, value) do
    log(:count, name, value)
  end

  @spec decrement_counter(any()) :: :ok | {:error, term()}
  def decrement_counter(name) do
    log(:count, name, -1)
  end

  @spec decrement_counter(any(), pos_integer()) :: :ok | {:error, term()}
  def decrement_counter(name, value) do
    log(:count, name, -value)
  end

  def update_histogram(name, fun) when is_function(fun, 0) do
    begin = :os.timestamp()
    result = fun.()
    duration = :timer.now_diff(:os.timestamp(), begin) / 1000
    # log(:measure, name, [:io_lib_format.fwrite_g(duration), ?m, ?s])
    log(:measure, name, duration)
    result
  end

  def update_histogram(name, value) when is_number(value) do
    log(:measure, name, value)
  end

  @spec update_gauge(any(), number()) :: :ok | {:error, term()}
  def update_gauge(name, value) do
    log(:sample, name, value)
  end

  @spec update_meter(any(), number()) :: :ok | {:error, term()}
  def update_meter(name, value) do
    log(:sample, name, value)
  end

  @spec notify(any(), any(), atom()) :: :ok | {:error, term()}
  def notify(name, value, op) do
    log(name, value, op)
    :ok
  end

  defp log(:count, name, value) do
    maybe_logger([:metrics, :count, name, value])
    :ok
  end

  defp log(:measure, [:hackney, uri, name | _], value) do
    maybe_logger([:metrics, :measure, uri, name, value])
    :ok
  end

  defp log(:measure, a, v) do
    maybe_logger([:metrics, :measure, a, v])
    :ok
  end

  defp log(op, [:hackney_pool, :default, name | _], value) do
    maybe_logger([:metrics, op, name, value])
    :ok
  end

  defp log(op, name, value) do
    maybe_logger([:metrics, op, name, value])
    :ok
  end

  defp maybe_logger(o) do
    debug(o)
  end
end
