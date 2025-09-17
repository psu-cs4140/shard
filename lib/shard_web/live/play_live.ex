defmodule ShardWeb.PlayLive do
  use ShardWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :msg, "Hello from /play")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 text-xl">{@msg}</div>
    """
  end
end
