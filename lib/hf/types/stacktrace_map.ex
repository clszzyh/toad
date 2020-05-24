defmodule Hf.Types.StacktraceMap do
  @moduledoc false
  use Hf.Type, :stacktrace_map

  @impl Type
  def load(%{"args" => args} = map) do
    {:ok, %{map | "args" => args |> Enum.map(&Util.encode64_to_term/1)} |> Util.atomize_keys()}
  end

  @impl Type
  def dump({module, method, arity, options}) when is_integer(arity) do
    inner_dump({module, method, arity, options})
  end

  def dump({module, method, args, options}) when is_list(args) do
    inner_dump({module, method, Enum.count(args), options}, args)
  end

  def inner_dump({module, method, arity, options}, args \\ []) do
    {:ok,
     %{
       module: module,
       method: method,
       arity: arity,
       args: Enum.map(args, &Util.term_to_encode64/1),
       options: options |> Map.new() |> maybe_update_file
     }}
  end

  def maybe_update_file(%{file: f} = a), do: %{a | file: to_string(f)}
  def maybe_update_file(a), do: a
end
