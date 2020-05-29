defmodule HfWeb.ApiIndexLive do
  use HfWeb.LiveView

  def render(assigns) do
    ~L"""
    <div class="columns">
    <div class="column">
    First column
    </div>
    <div class="column">
    Second column
    </div>
    <div class="column">
    Third column
    </div>
    <div class="column">
    Fourth column
    </div>
    </div>
    """
  end

  def mount(%{}, _session, socket) do
    {:ok, socket |> assign(:last_update_at, Util.now())}
  end
end
