defmodule ShardWeb.Admin.CharactersLive do
  use ShardWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: nil, character_id: nil)}
  end

  # Router sets @live_action; we use it to vary the UI.
  @impl true
  def handle_params(params, _uri, socket) do
    action = socket.assigns.live_action

    socket =
      socket
      |> assign(:page_title, page_title(action))
      |> assign(:character_id, Map.get(params, "id"))

    {:noreply, socket}
  end

  defp page_title(:index), do: "Admin • Characters"
  defp page_title(:new), do: "New Character"
  defp page_title(:show), do: "Character"
  defp page_title(:edit), do: "Edit Character"
  defp page_title(_), do: "Characters"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 space-y-4">
      <h1 class="text-2xl font-semibold">{@page_title || "Characters"}</h1>

      <%= if @live_action == :index do %>
        <p class="text-zinc-500">Characters index placeholder.</p>
      <% end %>

      <%= if @live_action == :new do %>
        <p class="text-zinc-500">New character form placeholder.</p>
      <% end %>

      <%= if @live_action == :show do %>
        <p class="text-zinc-500">
          Showing character with id: <span class="font-mono">{@character_id}</span>
        </p>
      <% end %>

      <%= if @live_action == :edit do %>
        <p class="text-zinc-500">
          Editing character with id: <span class="font-mono">{@character_id}</span>
        </p>
      <% end %>
    </div>
    """
  end
end
