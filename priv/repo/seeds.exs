# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Hf.Repo.insert!(%Hf.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

use Hf.Http.Config

G |> Repo.delete_all()

:hf
|> Application.app_dir("priv/data/groups.exs")
|> Code.eval_file()
|> elem(0)
|> Enum.map(fn a -> %G{} |> G.changeset(a) |> Repo.insert!() end)

A |> Repo.delete_all()

:hf
|> Application.app_dir("priv/data/apis.exs")
|> Code.eval_file()
|> elem(0)
|> Enum.map(fn a -> %A{} |> A.changeset(a) |> Repo.insert!() end)
