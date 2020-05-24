defmodule Hf.Types.TupleMethod do
  @moduledoc false
  use Hf.Type, :tuple_method

  @impl Type
  def load(%{"name" => name} = a) when is_binary(name) do
    {:ok, {String.to_atom(name), Enum.map(a, &load_ast/1) |> Enum.reject(&is_nil/1)}}
  end

  @impl Type
  def dump({name, [_ | _] = value}) when is_atom(name) do
    {:ok, value |> Enum.flat_map(&dump_ast/1) |> Enum.into(%{"name" => name})}
  end

  defp dump_ast({k, ast}) do
    [
      {to_string(k), Util.term_to_encode64(ast)},
      {"#{k}_display", ast |> Macro.to_string() |> Code.format_string!() |> Enum.join()}
    ]
  end

  defp load_ast({k, value}) when k in ["args", "when", "body"] do
    {String.to_atom(k), Util.encode64_to_term(value)}
  end

  defp load_ast({k, value}) when k in ["args_display", "when_display", "body_display"] do
    {String.to_atom(k), value}
  end

  defp load_ast({_, _}), do: nil
end
