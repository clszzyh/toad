defmodule Hf.Workers.RequestWorker do
  use Hf.Worker, queue: :events, max_attempts: 3

  @impl Oban.Worker
  def backoff(%Job{}), do: 0

  @impl Oban.Worker
  def perform(%Job{args: %{} = input, attempt: 0} = job) do
    request_1(nil, input, job)
  end

  def perform(%Job{args: %{} = input, id: id} = job) do
    R
    |> Domain.one(%{by: [job_id: id]})
    |> case do
      nil -> nil
      %R{} = r -> r
    end
    |> request_1(input, job)
  end

  def request_1(
        r,
        %{"module" => mod, "input" => %{} = input},
        %Job{id: job_id, attempt: attempt, max_attempts: max_attempts} = job
      ) do
    input =
      %{input | "job_id" => job_id, "max_attempts" => max_attempts, "attempt" => attempt}
      |> build_input(r)

    request_2({mod, input}, job)
  end

  def build_input(input, nil), do: input

  def build_input(input, %R{id: id, trace: trace}) do
    input |> Map.merge(%{"id" => id, "trace" => trace})
  end

  def request_2({mod, %{} = input}, %Job{}) do
    module = mod |> String.to_existing_atom()

    {state, result, a} = module |> Fetcher.rq(input)

    oban_result =
      case state do
        :ok -> :ok
        :failed -> {:error, result}
        error when error in [:error, :fatal] -> :discard
      end

    error(Api.prefix(a) ++ Api.suffix(a), box: :after, prefix: "ob ")

    oban_result
  end
end

# :ok ->
#   %{exec | state: :success}
# {:ok, _result} ->
#   %{exec | state: :success}
# :discard ->
#   %{exec | state: :discard}
# {:error, error} ->
#   %{exec | state: :failure, kind: :error, error: error, stacktrace: current_stacktrace()}
# {:snooze, seconds} ->
#   %{exec | state: :snoozed, snooze: seconds}
