defmodule Hf.Http.Req.Input do
  use Hf.Http.Middleware

  def pipe(%Api{state: :ok, initial_input: %{} = initial_input, input: %{} = input} = a, %{} = i) do
    {input, a} =
      initial_input
      |> Map.merge(input)
      |> Map.merge(i)
      |> atomize_input()
      |> Map.put(:now, Util.now())
      |> Enum.reduce({%{}, a}, &parse_input/2)

    {:ok, input, %Api{a | input: input}}
  end

  defp atomize_input(input) when is_list(input), do: input |> Map.new() |> atomize_input()
  defp atomize_input(%{} = input), do: input |> Util.atomize_keys()
  defp atomize_input(%Api{} = a), do: a

  defp parse_input({:id, id}, {%{} = input, %Api{} = a}) do
    {input, %Api{a | rid: id}}
  end

  defp parse_input({:trace, trace}, {%{} = input, %Api{trace: old_trace} = a}) do
    {input, %Api{a | trace: old_trace ++ trace}}
  end

  defp parse_input({k, v}, {%{} = input, %Api{} = a}) do
    {input |> Map.put(k, v), a}
  end
end
