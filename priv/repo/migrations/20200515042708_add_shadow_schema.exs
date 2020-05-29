defmodule Hf.Repo.Migrations.AddShadowSchema do
  use Ecto.Migration

  @tables_setup ["apis", "groups"]
                |> Enum.map(fn name -> "select shadow.setup_jsonb('#{name}');" end)

  def up do
    sqls =
      File.read!("priv/repo/shadow.sql")
      |> String.split("\n\n")
      |> Kernel.++(@tables_setup)

    Enum.each(sqls, &execute/1)
    repo().query!("select 'Up query …';", [], log: :info)
  end

  def down do
    repo().query!("select 'Down query …';", [], log: :info)
    execute "DROP SCHEMA IF EXISTS shadow CASCADE;"
  end
end
