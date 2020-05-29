defmodule Hf.Types.TraceMap do
  @moduledoc false
  use Hf.Type, :trace_map

  @impl Type
  def load(%{
        "index" => index,
        "kind" => kind,
        "cost" => cost,
        "middleware" => middleware,
        "attempt" => attempt,
        "state" => state,
        "result" => result
      }) do
    {:ok,
     {index,
      {{attempt, String.to_atom(kind), String.to_atom(middleware), cost},
       {String.to_atom(state), Util.load_value(result)}}}}
  end

  @impl Type
  def dump({index, {{attempt, kind, middleware, cost}, {state, result}}})
      when is_integer(index) and is_atom(kind) and is_atom(middleware) and is_atom(state) do
    {:ok,
     %{
       "index" => index,
       "kind" => kind,
       "cost" => cost,
       "middleware" => middleware,
       "attempt" => attempt,
       "state" => state,
       "display" => inspect(result),
       "result" => Util.dump_value(result)
     }}
  end
end
