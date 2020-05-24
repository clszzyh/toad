defmodule Hf.Concern.Queryable do
  alias Ecto.Adapters.SQL
  import Ecto.Query
  alias Ecto.Query
  alias Ecto.Query.FromExpr
  alias Hf.Repo

  def build_all(%Query{} = query) do
    query |> Repo.all()
  end

  def build_sql(%Query{} = query) do
    SQL.to_sql(:all, Repo, query)
  end

  def build_page(%Query{} = query, params \\ %{}) do
    query |> Repo.paginate(params)
  end

  def q(module, params \\ %{}, options \\ [])

  def q(%Query{} = query, params, options) do
    query
    |> compose_query(params)
    |> case do
      %Query{from: %FromExpr{source: {_, module}}} = q ->
        if options[:unscoped] do
          q
        else
          q |> module.default_query()
        end

      {:error, reason} ->
        raise(reason)
    end
  end

  def q(module, params, options), do: q(from(_ in module), params, options)

  defp compose_query(%Query{} = query, %{} = conditions) do
    conditions
    |> Enum.map(fn x -> x end)
    |> Enum.sort_by(fn {op, _} -> op == :join end, :desc)
    |> Enum.reduce(query, fn a, b -> compose_query(b, a) end)
  end

  defp compose_query(%Query{} = query, {:preload, values}) do
    query |> preload(^values)
  end

  defp compose_query(%Query{} = query, {_, []}), do: query
  defp compose_query(%Query{} = query, {_, %{} = map}) when map_size(map) == 0, do: query

  defp compose_query(%Query{} = query, {ignored_key, _}) when ignored_key in [:page, :page_size],
    do: query

  defp compose_query(%Query{} = query, {op, [{field, value} | rest]}) do
    query |> compose_query({op, {field, value}}) |> compose_query({op, rest})
  end

  defp compose_query(%Query{from: %FromExpr{source: {_, module}}} = query, {:join, a}) do
    query |> module.compose_query({:join, a})
  end

  defp compose_query(%Query{} = query, {:by, {{n, field}, nil}}) when is_atom(field) do
    query |> where([{^n, i}], is_nil(field(i, ^field)))
  end

  defp compose_query(%Query{} = query, {:by, {field, nil}}) when is_atom(field) do
    query |> where([i], is_nil(field(i, ^field)))
  end

  defp compose_query(%Query{} = query, {:by, {{n, field}, value}}) when is_atom(field) do
    query |> where([{^n, i}], field(i, ^field) == ^value)
  end

  defp compose_query(%Query{} = query, {:by, {field, value}}) when is_atom(field) do
    query |> where([i], field(i, ^field) == ^value)
  end

  defp compose_query(%Query{} = query, {:not_by, {{n, field}, nil}}) when is_atom(field) do
    query |> where([{^n, i}], not is_nil(field(i, ^field)))
  end

  defp compose_query(%Query{} = query, {:not_by, {field, nil}}) when is_atom(field) do
    query |> where([i], not is_nil(field(i, ^field)))
  end

  defp compose_query(%Query{} = query, {:not_by, {{n, field}, value}}) when is_atom(field) do
    query |> where([{^n, i}], field(i, ^field) != ^value)
  end

  defp compose_query(%Query{} = query, {:not_by, {field, value}}) when is_atom(field) do
    query |> where([i], field(i, ^field) != ^value)
  end

  defp compose_query(%Query{} = query, {:in, {{n, field}, value}})
       when is_list(value) and is_atom(field) do
    query |> where([{^n, i}], field(i, ^field) in ^value)
  end

  defp compose_query(%Query{} = query, {:in, {field, value}})
       when is_list(value) and is_atom(field) do
    query |> where([i], field(i, ^field) in ^value)
  end

  defp compose_query(%Query{} = query, {:not_in, {{n, field}, value}})
       when is_list(value) and is_atom(field) do
    query |> where([{^n, i}], field(i, ^field) not in ^value)
  end

  defp compose_query(%Query{} = query, {:not_in, {field, value}})
       when is_list(value) and is_atom(field) do
    query |> where([i], field(i, ^field) not in ^value)
  end

  defp compose_query(%Query{} = query, {:order, {sort, field}})
       when sort in [:asc, :desc] and is_atom(field),
       do: query |> order_by({^sort, ^field})

  defp compose_query(%Query{}, {_, _} = a), do: {:error, "Not support: #{inspect(a)}"}

  defp compose_query({:error, reason}, _), do: {:error, reason}
end
