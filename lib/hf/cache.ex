defmodule Hf.Cache do
  @moduledoc false

  import Hf.LocalLogger
  use Decorator.Define, cache: 0, cache: 1

  @cache_name :app_cache

  @proxy_methods [
    get: 1,
    get!: 1,
    put: 2,
    put!: 2,
    put: 3,
    put!: 3,
    keys: 0,
    purge: 0,
    del: 1,
    expire: 2,
    expire_at: 2,
    count: 0,
    stats: 0,
    ttl: 1,
    inspect: 1,
    export: 0,
    fetch: 2
  ]

  for {name, arity} <- @proxy_methods do
    args = Macro.generate_arguments(arity, __MODULE__)

    def unquote(name)(unquote_splicing(args)) do
      Cachex.unquote(name)(unquote(@cache_name), unquote_splicing(args))
    end
  end

  def cache(body, context), do: cache(nil, body, context)

  def cache(options, body, %{module: module, name: name, arity: arity, args: args}) do
    method_name = "#{module}.#{name}/#{arity}"
    cache_key = {method_name, args}

    quote do
      alias unquote(__MODULE__)
      alias Hf.LocalLogger
      cache_key = unquote(cache_key)

      cache_key
      |> Cache.get()
      |> case do
        {:ok, truthy} when truthy not in [nil] ->
          LocalLogger.debug([:match_cache, cache_key])
          {:ok, truthy}

        _ ->
          case unquote(body) do
            {:ok, result} ->
              Cache.put(cache_key, result)
              Cache.maybe_expire_cache(cache_key, result, unquote(options))

              LocalLogger.info([:put_cache, cache_key])
              {:ok, result}

            other ->
              other
          end
      end
    end
  end

  def maybe_expire_cache(cache_key, result, options) do
    inner_maybe_expire_cache(cache_key, result, options)
    |> case do
      {:ok, _} -> :ok
      {:error, v} -> error([:expire_cache_error, cache_key, v])
    end
  end

  defp inner_maybe_expire_cache(cache_key, result, {:expire_at, v}) do
    result
    |> Access.get(v)
    |> case do
      nil ->
        {:error, v}

      t ->
        debug([:expire_key, cache_key, t])
        __MODULE__.expire_at(cache_key, t * 1000)
    end
  rescue
    e -> {:error, use(Hf.ReportError, type: :expire_cache, reason: e, stacktrace: __STACKTRACE__)}
  end

  defp inner_maybe_expire_cache(_, _, _), do: {:ok, true}
end
