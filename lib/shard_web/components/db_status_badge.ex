defmodule ShardWeb.DBStatusBadge do
  use Phoenix.Component

  attr :health, :map, required: true

  # Call with: <.db_status_badge health={@db_health} />
  def db_status_badge(assigns) do
    ~H"""
    <%= case @health do %>
      <% %{reachable?: true, pending: 0} -> %>
        <span class="px-2 py-1 rounded text-xs bg-green-600/80 text-white">DB ✓</span>
      <% %{reachable?: true, pending: :unknown} -> %>
        <span class="px-2 py-1 rounded text-xs bg-yellow-600/80 text-white">DB ?</span>
      <% %{reachable?: true, pending: n} when is_integer(n) and n > 0 -> %>
        <span class="px-2 py-1 rounded text-xs bg-yellow-600/80 text-white">DB ! <%= n %></span>
      <% _ -> %>
        <span class="px-2 py-1 rounded text-xs bg-red-600/80 text-white">DB ✕</span>
    <% end %>
    """
  end
end

