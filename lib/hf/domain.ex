defmodule Hf.Domain do
  import Hf.Concern.Queryable
  import Ecto.Query
  alias Ecto.Changeset
  alias Hf.Domain.Api, as: A
  alias Hf.Domain.Job, as: J
  alias Hf.Domain.Record, as: R
  alias Hf.Http.{Api, Core, Dynamic}
  alias Hf.Repo

  def page(module, params \\ %{}) do
    query = q(module, params)
    sql = query |> build_sql()
    data = query |> build_page(params)
    %{sql: sql, data: data}
  end

  def find(module, id) do
    module |> Repo.get!(id)
  end

  def one(module, params) do
    module |> q(params) |> limit(1) |> Repo.one()
  end

  def one!(module, params) do
    module |> q(params) |> limit(1) |> Repo.one!()
  end

  def insert(module, %{} = params) do
    %Changeset{changes: %{} = changes} =
      changeset = module |> struct() |> module.changeset(params)

    {code, result} = changeset |> Repo.insert()
    {code, changes, result}
  end

  def update(module, %{} = params, id) when is_integer(id) do
    %Changeset{changes: %{} = changes} =
      changeset =
      module
      |> find(id)
      |> module.changeset(params)

    {code, result} = changeset |> Repo.update()
    {code, changes, result}
  end

  def maybe_resume_api!(%R{state: :ok} = r), do: r

  def maybe_resume_api!(%R{state: :paused} = r) do
    r |> R.changeset(%{state: :ok}) |> Repo.update!()
  end

  defmacro transaction(user_id, do: block) do
    quote do
      Repo.transaction(fn ->
        if unquote(user_id), do: {:ok, _} = Repo.config_session_user_id!(unquote(user_id))
        unquote(block)
      end)
    end
  end

  def fetch_job!(job_id) do
    J
    |> find(job_id)
    |> Repo.preload(:req)
    |> case do
      %J{req: %R{} = req} = j ->
        %R{api: %Api{} = a} = r = Core.load(req)
        %J{j | req: %R{r | api: nil}, api: a}

      j ->
        j
    end
  end

  def apis do
    A |> Repo.all() |> Repo.preload(:g)
  end

  def next_version(%A{name: name}) do
    A |> where([a], a.name == ^name) |> select([a], max(a.version) + 1) |> Repo.one!()
  end

  def duplicate_api(%A{} = a) do
    fields = A.meta().permitted_fields
    o = a |> Map.take(fields)
    %A{} |> A.changeset(%{o | version: next_version(a)}) |> Repo.insert()
  end

  def update_api(%A{} = a, %{} = params) do
    Repo.transaction(fn ->
      result =
        a
        |> A.changeset(params)
        |> Repo.update()
        |> case do
          {:ok, a} ->
            a
            |> Dynamic.compile()
            |> case do
              {:ok, {_, module}} -> {a, module}
              {:error, {_, reason}} -> {:error, reason}
            end

          {:error, reason} ->
            {:error, reason}
        end

      case result do
        {:error, reason} -> Repo.rollback(reason)
        o -> o
      end
    end)
    |> case do
      {:ok, result} -> {:ok, result}
      {:error, e} -> {:error, use(Hf.ReportError, type: :update_api, reason: e)}
    end
  end

  def update_duplicate_api(%A{} = a, %{} = params) do
    Repo.transaction(fn ->
      with {:ok, a} <- duplicate_api(a),
           {:ok, result} <- update_api(a, params) do
        result
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  def jobs(params \\ %{}) do
    page(
      J,
      %{
        order: [desc: :id],
        page_size: 5,
        preload: [:req],
        by: [worker: "Hf.Workers.RequestWorker"]
      }
      |> Map.merge(params)
    )
  end
end
