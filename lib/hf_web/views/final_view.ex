defmodule HfWeb.FinalView do
  use HfWeb, :view

  def render("result.json", %{data: data}) do
    data
  end
end
