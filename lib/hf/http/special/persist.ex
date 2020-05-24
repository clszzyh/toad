defmodule Hf.Http.Special.Persist do
  use Hf.Http.Middleware

  def pipe(%Api{} = a, %{kind: kind, stage: stage}) do
    a
    |> Persist.request_params({kind, stage})
    |> Persist.merge_params(a)
    |> Persist.insert_or_update_request(a)
    |> maybe_broadcast({kind, stage})
    |> persist_result(a, {kind, stage})
  end

  def pipe(_, _), do: {:error, :persist_match_error}

  defp maybe_broadcast({persist_kind, :ok, changes, %R{job_id: job_id}} = i, {kind, stage}) do
    if map_size(changes) > 0 do
      Hf.maybe_broadcast_api(
        job_id,
        {persist_kind, %{kind: kind, stage: stage, changes: changes}}
      )
    end

    i
  end

  defp persist_result({_, _, _, %R{id: id, state: :paused}}, %Api{} = a, {:req, _}) do
    {:fatal, :paused, %Api{a | rid: id}}
  end

  defp persist_result({_, _, %{} = changes, %R{id: id}}, %Api{} = a, {:req, _})
       when map_size(changes) == 0 do
    {:ignored, id, %Api{a | rid: id}}
  end

  defp persist_result({_, _, _, %R{id: id}}, %Api{} = a, {:req, _}),
    do: {:ok, id, %Api{a | rid: id}}

  defp persist_result({_, _, _, %R{id: _}}, %Api{result: result}, _), do: {:ok, result}
  defp persist_result(_, _, _), do: {:error, :persist_error}
end
