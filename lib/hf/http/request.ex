defmodule Hf.Http.Request do
  use Hf.Http.Common

  def do_request(%Api{state: :ok, persist: persist, extra: extra, req: %Req{} = req} = a) do
    start = System.monotonic_time()
    # {cost, result} = :timer.tc(HTTPoison, :request, [req])
    result = HTTPoison.request(req)
    duration = System.monotonic_time() - start

    timeout =
      (System.convert_time_unit(duration, :native, :millisecond) * 0.001) |> Float.round(3)

    a =
      case result do
        {:ok, %Resp{status_code: status_code} = resp} ->
          %Api{a | resp: resp, result: {status_code, timeout}}

        {:error, %Error{reason: reason}} ->
          %Api{a | state: :failed, result: reason}
      end

    %Api{
      a
      | extra: Map.merge(extra, %{duration: duration}),
        persist: Map.merge(persist, %{timeout: timeout})
    }
    |> Fetcher.trace(:do_request)
  end

  def do_request(%Api{} = a), do: a
end
