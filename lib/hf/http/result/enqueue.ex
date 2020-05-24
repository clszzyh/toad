defmodule Hf.Http.Result.Enqueue do
  use Hf.Http.Middleware

  def pipe(%Api{state: :ok, rid: parent_id}, %{enqueue: enqueue}) do
    {should_enqueue, module, input} =
      case enqueue do
        {mod, %{} = input} ->
          {true, mod, input}

        mod when is_atom(mod) ->
          {true, mod, %{}}

        _ ->
          {false, nil, nil}
      end

    if should_enqueue do
      %J{id: id} = Fetcher.enqueue(module, input |> Map.put(:parent_id, parent_id))
      {:ok, id}
    else
      :ignored
    end
  end
end
