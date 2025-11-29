defmodule ShardWeb.AchievementLive do
  @moduledoc """
  LiveView component for handling achievement notifications.
  This component subscribes to achievement PubSub messages and triggers frontend notifications.
  """
  
  use ShardWeb, :live_view
  
  def mount(_params, %{"user_token" => user_token} = _session, socket) do
    user = Shard.Users.get_user_by_session_token(user_token)
    
    if user do
      # Subscribe to achievement notifications for this user
      Phoenix.PubSub.subscribe(Shard.PubSub, "user:#{user.id}")
      
      {:ok, assign(socket, :user, user)}
    else
      {:ok, assign(socket, :user, nil)}
    end
  end
  
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :user, nil)}
  end
  
  def handle_info({:achievement_unlocked, payload}, socket) do
    # Send achievement notification to frontend
    {:noreply, push_event(socket, "achievement_unlocked", payload)}
  end
  
  def render(assigns) do
    ~H"""
    <div id="achievement-notifications" phx-hook="AchievementNotifications" class="hidden"></div>
    """
  end
end
