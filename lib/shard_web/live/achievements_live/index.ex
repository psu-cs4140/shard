defmodule ShardWeb.AchievementsLive.Index do
  use ShardWeb, :live_view

  alias Shard.Achievements

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    achievements = Achievements.list_achievements()
    user_achievements = Achievements.get_user_achievements(user)
    stats = Achievements.get_user_achievement_stats(user)

    # Create a map of earned achievement IDs for quick lookup
    earned_achievement_ids =
      user_achievements
      |> Enum.map(fn {_user_achievement, achievement} -> achievement.id end)
      |> MapSet.new()

    socket =
      socket
      |> assign(:achievements, achievements)
      |> assign(:user_achievements, user_achievements)
      |> assign(:stats, stats)
      |> assign(:earned_achievement_ids, earned_achievement_ids)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Achievements")
  end
end
