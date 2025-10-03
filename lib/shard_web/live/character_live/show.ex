defmodule ShardWeb.CharacterLive.Show do
  use ShardWeb, :live_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(%{"id" => id}, _url, socket), do: {:noreply, assign(socket, id: id)}

  @impl true
  def render(assigns) do
    ~H"""
    <section class="p-6 space-y-3">
      <h1 class="text-2xl font-semibold">Character {@id}</h1>
      <p>Details page coming soon.</p>
      <.link navigate={~p"/characters"} class="btn btn-ghost mt-4">Back</.link>
    </section>
    """
  end
end
