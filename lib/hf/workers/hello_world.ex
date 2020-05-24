defmodule Hf.Workers.HelloWorld do
  use Hf.Worker, queue: :events, max_attempts: 10

  @impl Oban.Worker
  def backoff(%Job{}), do: 0

  @impl Oban.Worker
  def perform(%Job{args: %{}, attempt: attempt}) when attempt > 3 do
    info([:hello_world, attempt])
    {:ok, :hello_world}
  end

  def perform(%Job{args: %{} = args, id: job_id}) do
    info([:hello_world, args, job_id])
    # {:error, :reason}
    {:ok, :hello_world}
  end
end
