defmodule ShardWeb.Admin.MapLive do
  use ShardWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Admin Map")}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h1 class="text-2xl font-semibold">Admin Map</h1>
      <p class="mt-2 text-zinc-500">This is a placeholder. Wire in your map editor here.</p>
    </div>
    """
  end
end
