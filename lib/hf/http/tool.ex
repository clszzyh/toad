defmodule Hf.Http.Tool do
  @moduledoc false
  alias Hf.Http.Registry

  @default_map %{job_id: nil, parent_id: nil, max_attempts: 0, attempt: 0}

  def merge_input(input) when is_list(input) or is_map(input) do
    @default_map |> Map.merge(Map.new(input))
  end

  def merge_input(input), do: merge_input(%{i: input})

  def map_to_list(%{} = map) do
    for {k, v} <- map, do: {k, map_to_list(v)}
  end

  def map_to_list(v), do: v

  def list_to_keyword(v) do
    Enum.map(v, &term_to_keyword_tuple/1)
  end

  def stringify_keys(%{} = map) do
    map
    |> Enum.map(fn {k, v} -> {stringify_key(k), stringify_keys(v)} end)
    |> Enum.into(%{})
  end

  def stringify_key(key) when is_atom(key), do: Atom.to_string(key)
  def stringify_key(key), do: key

  def term_to_keyword_tuple({_, _} = v), do: v
  def term_to_keyword_tuple(v) when is_atom(v), do: {v, []}

  def merge_keyword(k1, k2) do
    Keyword.merge(k1, k2, &merge_term/3)
  end

  def merge_map_like(v1, v2) do
    merge_map(Map.new(v1), Map.new(v2))
  end

  def merge_map(%{} = v1, %{} = v2) do
    Map.merge(v1, v2, &merge_term/3)
  end

  def merge_term(_, [{_, _} | _] = v1, [{_, _} | _] = v2), do: merge_keyword(v1, v2)
  def merge_term(_, %{} = v1, %{} = v2), do: merge_map(v1, v2)
  def merge_term(_, _, v2), do: v2

  def optional_filter(base_list, [], new_result), do: {base_list, new_result}
  def optional_filter([], _, new_list), do: {[], new_list}

  def optional_filter(base_list, [{module, new_options} | rest], new_result) do
    base_list
    |> Enum.find(fn {mod, _} -> mod == module end)
    |> case do
      nil ->
        optional_filter(base_list, rest, new_result)

      {_, _} ->
        optional_filter(
          base_list
          |> Enum.map(fn {mod, options} ->
            if mod == module do
              {mod, merge_keyword(options, new_options)}
            else
              {mod, options}
            end
          end),
          rest,
          new_result |> Enum.reject(&match?({^module, _}, &1))
        )
    end
  end

  def defined?(module) do
    module
    |> Code.ensure_compiled()
    |> case do
      {:module, _} -> true
      _ -> false
    end
  end

  def api_name(module) do
    Registry.name(module) || raise("[name]: 找不到 #{module}")
  end

  def api_cast(name, version \\ 0)

  def api_cast(name, %{version: version}) when is_integer(version), do: api_cast(name, version)
  def api_cast(name, input) when is_list(input), do: api_cast(name, input[:version] || 0)
  def api_cast(name, %{}), do: api_cast(name, 0)

  def api_cast(name, version) when is_binary(name) and is_integer(version),
    do: name |> String.to_atom() |> api_cast(version)

  def api_cast(name, version) when is_atom(name) and is_integer(version) do
    if defined?(name) do
      name
    else
      Registry.module({name, version}) || raise("[module]: 找不到#{name} #{version}")
    end
  end

  def api_cast(name, _), do: api_cast(name, %{})

  def name_to_module(name) do
    n =
      name
      |> to_string
      |> Macro.camelize()

    ["Req", "Resp", "Result", "Special"]
    |> Enum.map(fn x -> Module.concat([Hf.Http, x, n]) end)
    |> Enum.find(&defined?/1)
    |> case do
      nil -> raise("Middleware not found: #{name}")
      o -> o
    end
  end
end
