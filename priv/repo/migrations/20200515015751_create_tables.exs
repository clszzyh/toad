defmodule Hf.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    create table(:history) do
      add :pk, :bigint, null: false
      add :table_name, :string, null: false
      add :data, :map, default: %{}
      add :op, :string, size: 1
      add :query, :varchar
      add :app_session_user_id, :string
      add :inserted_at, :utc_datetime, null: false
    end

    create index(:history, [:pk])

    create table(:proxys) do
      add :source, :string, null: false
      add :state, :integer, null: false
      add :proxy, :string, null: false
      add :reason, :string, size: 1000
      add :cost, :integer
      add :record_id, :bigint
      add :job_id, :bigint
      add :validated_at, :utc_datetime
      add :expired_at, :utc_datetime
      add :payload, :json
      add :audit, :json

      timestamps()
    end

    create table(:errors) do
      add :kind, :integer, null: false
      add :type, :integer, null: false
      add :reason, :text
      add :eid, :bigint
      add :context, {:array, :map}
      add :stacktrace, {:array, :map}
      add :format_blamed, :text
      add :payload, :json
      timestamps()
    end

    create table(:bindings) do
      add :context, {:array, :map}
      add :payload, :json
      timestamps()
    end

    create table(:variables) do
      add :env, :string
      add :key, :string, null: false
      add :value, :string, null: false
      add :desc, :string
      add :payload, :map
      timestamps()
    end

    create index(:variables, [:env, :key], unique: true)

    create table(:groups) do
      add :name, :string, null: false
      add :tags, {:array, :string}, null: false, default: []
      add :pipes, {:array, :map}, null: false, default: []
      add :methods, {:array, :map}, null: false, default: []
      add :context, {:array, :map}, null: false, default: []
      add :input, {:array, :map}, null: false, default: []
      add :tests, {:array, :map}, null: false, default: []
      add :payload, :map
      timestamps()
    end

    create index(:groups, [:name], unique: true)

    create table(:apis) do
      add :name, :string, null: false
      add :version, :integer, null: false
      add :url, :string, null: false
      add :state, :integer, null: false
      add :kind, :integer, null: false
      add :env_id, :integer
      add :group, :string
      add :tags, {:array, :string}, null: false, default: []
      add :pipes, {:array, :map}, null: false, default: []
      add :methods, {:array, :map}, null: false, default: []
      add :context, {:array, :map}, null: false, default: []
      add :input, {:array, :map}, null: false, default: []
      add :tests, {:array, :map}, null: false, default: []
      add :payload, :map
      timestamps()
    end

    create index(:apis, [:name, :version], unique: true)

    create table(:environments) do
      add :name, :string, null: false
      timestamps()
    end

    create index(:environments, [:name], unique: true)

    create table(:tests) do
      add :api_id, :bigint
      add :source, :string, null: false
      add :kind, :string, null: false
      add :name, :string, null: false
      add :config, :map, null: false
      add :result, :text
      add :matched, :integer, null: false
      add :payload, :json
      timestamps()
    end

    create index(:tests, [:api_id])
    create index(:tests, [:source])

    create table(:records) do
      add :source, :string, null: false
      add :state, :integer, null: false
      add :content_type, :integer, null: false
      add :url, :string, size: 1000, null: false
      add :proxy, :string
      add :version, :integer
      add :attempt, :integer
      add :result, :text
      add :cost, :integer
      add :method, :integer, null: false
      add :trace, {:array, :map}, default: []
      add :extra, :map, default: %{}
      add :input, :map
      add :job_id, :bigint
      add :proxy_id, :bigint
      add :parent_id, :bigint
      add :test_id, :bigint

      add :raw, :binary
      add :payload, {:map, :string}
      add :history, :json
      add :data, :text
      add :target, :string, size: 1000
      add :api_id, :bigint

      timestamps()
    end

    create index(:records, [:parent_id])
    create index(:records, [:job_id])
    create index(:records, [:api_id])
    create index(:records, [:source])
    create index(:records, [:test_id])
  end
end
