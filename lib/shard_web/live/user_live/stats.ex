defmodule ShardWeb.UserLive.Stats do
  use ShardWeb, :live_view

  alias Shard.{Users, Characters}

  @impl true
  def mount(_params, %{"user_id" => user_id}, socket) do
    user = Users.get_user!(user_id)
    characters = Characters.get_characters_by_user(user_id)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:characters, characters)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h1 class="text-2xl font-bold mb-4">Player Stats</h1>

      <p><strong>Login Count:</strong> {@user.login_count}</p>
      <p><strong>Total Playtime (seconds):</strong> {@user.total_playtime_seconds}</p>

      <h2 class="text-xl font-semibold mt-6 mb-2">Characters</h2>

      <ul>
        <%= for char <- @characters do %>
          <li>{char.name} (Level {char.level})</li>
        <% end %>
      </ul>
    </div>
    """
  end
end
