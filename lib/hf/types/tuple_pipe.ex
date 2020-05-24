defmodule Hf.Types.TuplePipe do
  @moduledoc false
  use Hf.Type, :tuple_pipe

  @impl Type
  def load(%{"name" => name, "value" => _, "type" => _} = a) when is_binary(name) do
    {:ok, {String.to_atom(name), Util.load_value(a)}}
  end

  @impl Type
  def dump(v) when is_atom(v), do: dump({v, []})

  def dump({name, value}) when is_atom(name) do
    {:ok,
     %{
       "name" => to_string(name),
       "display" => inspect(value)
     }
     |> Map.merge(Util.dump_value(value))}
  end
end
