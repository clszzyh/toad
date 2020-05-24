defmodule Hf.Repo do
  use Ecto.Repo,
    otp_app: :hf,
    adapter: Ecto.Adapters.Postgres

  # https://github.com/duffelhq/paginator
  use Scrivener, page_size: 10
  import Ecto.Query, warn: false
  alias Ecto.Adapters.SQL
  alias Ecto.Query
  alias Ecto.Query.FromExpr

  def init(_, opts) do
    {:ok,
     opts
     |> Keyword.put(:url, System.fetch_env!("DATABASE_URL"))
     |> Keyword.put(:pool_size, String.to_integer(System.fetch_env!("POOL_SIZE")))
     |> Keyword.put(:timeout, 15_000)}
  end

  def select(sql) when is_binary(sql) do
    %Postgrex.Result{columns: columns, rows: rows} = query!(sql)

    columns
    |> Enum.with_index()
    |> Enum.into(%{}, fn {k, index} ->
      {k |> String.to_atom(),
       rows
       |> Enum.map(fn x -> Enum.at(x, index) end)
       |> case do
         [one] -> one
         o -> o
       end}
    end)
  end

  def now, do: select("select NOW()::timestamp;")
  def now_utc, do: select("select timezone('UTC', NOW())::timestamp;")
  def version, do: select("select version()")
  def select1, do: select("SELECT 1")

  def latest(query), do: query |> order_by(desc: :updated_at) |> limit(1) |> one |> show(query)
  def head(query), do: query |> first() |> one |> show(query)
  # def count(query), do: query |> select(count("*")) |> one
  def count(query), do: query |> select(count("*")) |> one
  # def count(query), do: aggregate(query, :count, "*")
  def tail(query), do: query |> last() |> one |> show(query)

  def pluck(query, fields), do: query |> select([e, ...], map(e, ^fields)) |> all
  def find(query, id), do: query |> __MODULE__.get(id) |> show(query)

  def show(%module{} = o, %Query{from: %FromExpr{source: {_, module}}}), do: show(o, module)
  def show(%module{} = o, module), do: o |> module.show()
  def show(o, _), do: o

  def raw(%{} = a) do
    o = a |> query
    struct(a.__struct__, o)
  end

  def config_session_user_id!(id) when is_binary(id) do
    SQL.query(__MODULE__, "SELECT set_config('app.session_user_id', $1, true)", [id])
  end

  def sql(%Query{} = query) do
    :all |> SQL.to_sql(__MODULE__, query) |> elem(0)
  end

  def sql(module), do: from(_ in module) |> sql()

  def query(%{__meta__: %{source: source}, id: id}) do
    "SELECT * FROM #{source} WHERE id = #{id}" |> query
  end

  def query(%Query{} = q), do: q |> sql() |> query()
  def query(sql) when is_binary(sql), do: select(sql)

  def select_all(query, field),
    do: query |> select([r], {r.id, field(r, ^field)}) |> all |> Enum.into(%{})

  def group_by_count(query, field) when is_atom(field),
    do: query |> group_by(^field) |> select([r], {field(r, ^field), count(r.id)}) |> all

  def group_by_count(query, [first | _] = fields) do
    query
    |> group_by(^fields)
    |> select([r], {map(r, ^fields), count(r.id)})
    |> all
    |> Enum.group_by(fn {map, _} -> map[first] end, fn {%{} = m, count} ->
      {m |> Map.delete(first) |> Map.values() |> Enum.join("_"), count}
    end)
    |> Enum.into(%{}, fn {k, ary} -> {k, ary |> Enum.into(%{})} end)
  end

  def max_value(query, field), do: query |> select([r], max(field(r, ^field))) |> one
  def min_value(query, field), do: query |> select([r], min(field(r, ^field))) |> one
  def avg_value(query, field), do: query |> select([r], avg(field(r, ^field))) |> one

  def export_methods do
    [
      tail: 0,
      count: 0,
      head: 0,
      latest: 0,
      find: 1,
      group_by_count: 1,
      max_value: 1,
      min_value: 1,
      avg_value: 1,
      select_all: 1,
      pluck: 1
    ]
  end
end
