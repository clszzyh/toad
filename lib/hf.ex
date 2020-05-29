defmodule Hf do
  @moduledoc """
  Hf keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  import Hf.LocalLogger

  def hide_debug!(level \\ :local)
  def hide_debug!(:local), do: Application.put_env(:hf, :app_log_level, :info)
  def hide_debug!(:all), do: Logger.configure(level: :info)

  def show_debug!(level \\ :local)
  def show_debug!(:local), do: Application.put_env(:hf, :app_log_level, :debug)
  def show_debug!(:all), do: Logger.configure(level: :debug)

  def subscribe(topic), do: Phoenix.PubSub.subscribe(Hf.PubSub, topic)

  def broadcast(topic, {kind, object}) do
    result = Phoenix.PubSub.broadcast(Hf.PubSub, topic, {kind, object})
    debug([:broadcast, topic, result, kind])
    result
  end

  def pubsub_key(job_id, :api), do: "api:#{job_id}"

  def subscribe_api(job_id) when job_id not in [nil, ""],
    do: job_id |> pubsub_key(:api) |> subscribe()

  def maybe_broadcast_api(nil, _), do: :ok
  def maybe_broadcast_api(job_id, {_, _} = obj), do: job_id |> pubsub_key(:api) |> broadcast(obj)
end
