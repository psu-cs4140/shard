defmodule ShardWeb.RewardsLive.Index do
  use ShardWeb, :live_view

  alias Shard.Rewards

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    
    socket = 
      socket
      |> assign(:user_id, user_id)
      |> assign(:page_title, "Daily Rewards")
      |> load_reward_status()
    
    {:ok, socket}
  end

  @impl true
  def handle_event("claim_reward", _params, socket) do
    case Rewards.claim_daily_reward(socket.assigns.user_id) do
      {:ok, reward_info} ->
        socket = 
          socket
          |> put_flash(:info, format_reward_message(reward_info))
          |> load_reward_status()
        
        {:noreply, socket}
        
      {:error, :already_claimed_today} ->
        socket = put_flash(socket, :error, "You have already claimed your daily reward today!")
        {:noreply, socket}
        
      {:error, reason} ->
        socket = put_flash(socket, :error, "Unable to claim reward: #{reason}")
        {:noreply, socket}
    end
  end

  defp load_reward_status(socket) do
    user_id = socket.assigns.user_id
    
    case Rewards.can_claim_daily_reward?(user_id) do
      {:ok, status} ->
        current_streak = Rewards.get_current_streak(user_id)
        
        socket
        |> assign(:can_claim, status == :can_claim)
        |> assign(:already_claimed, status == :already_claimed)
        |> assign(:current_streak, current_streak)
        
      {:error, _reason} ->
        socket
        |> assign(:can_claim, false)
        |> assign(:already_claimed, false)
        |> assign(:current_streak, 0)
    end
  end

  defp format_reward_message(reward_info) do
    base_msg = "Daily reward claimed! You received #{reward_info.gold} gold"
    
    streak_msg = if reward_info.streak_bonus > 0 do
      " (including #{reward_info.streak_bonus} streak bonus)"
    else
      ""
    end
    
    lootbox_msg = if reward_info.lootbox do
      " and a #{reward_info.lootbox}!"
    else
      "!"
    end
    
    base_msg <> streak_msg <> lootbox_msg
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-center mb-2">Daily Login Rewards</h1>
        <p class="text-center text-base-content/70">
          Claim your daily reward to receive gold and a chance for a lootbox!
        </p>
      </div>

      <div class="card bg-base-200 shadow-xl">
        <div class="card-body">
          <div class="text-center mb-6">
            <div class="stat">
              <div class="stat-title">Current Streak</div>
              <div class="stat-value text-primary"><%= @current_streak %></div>
              <div class="stat-desc">
                <%= if @current_streak > 0 do %>
                  Keep it up! +<%= min(@current_streak * 10, 500) %> bonus gold
                <% else %>
                  Start your streak today!
                <% end %>
              </div>
            </div>
          </div>

          <div class="divider"></div>

          <div class="text-center">
            <h3 class="text-xl font-semibold mb-4">Today's Reward</h3>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
              <div class="card bg-base-100 shadow">
                <div class="card-body items-center text-center">
                  <h4 class="card-title text-yellow-500">💰 Gold</h4>
                  <p class="text-2xl font-bold">
                    <%= 100 + min(@current_streak * 10, 500) %>
                  </p>
                  <p class="text-sm text-base-content/70">Guaranteed</p>
                </div>
              </div>
              
              <div class="card bg-base-100 shadow">
                <div class="card-body items-center text-center">
                  <h4 class="card-title text-purple-500">📦 Lootbox</h4>
                  <p class="text-2xl font-bold">50%</p>
                  <p class="text-sm text-base-content/70">Chance</p>
                </div>
              </div>
            </div>

            <div class="card-actions justify-center">
              <%= if @can_claim do %>
                <button 
                  class="btn btn-primary btn-lg"
                  phx-click="claim_reward"
                >
                  🎁 Claim Daily Reward
                </button>
              <% else %>
                <button class="btn btn-disabled btn-lg" disabled>
                  <%= if @already_claimed do %>
                    ✅ Already Claimed Today
                  <% else %>
                    ❌ Cannot Claim
                  <% end %>
                </button>
              <% end %>
            </div>

            <%= if @already_claimed do %>
              <p class="text-sm text-base-content/70 mt-4">
                Come back tomorrow for your next reward!
              </p>
            <% end %>
          </div>
        </div>
      </div>

      <div class="mt-8">
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <h3 class="card-title">Streak Bonuses</h3>
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Streak Days</th>
                    <th>Bonus Gold</th>
                    <th>Total Gold</th>
                  </tr>
                </thead>
                <tbody>
                  <tr class={if @current_streak == 1, do: "bg-primary/20"}>
                    <td>1</td>
                    <td>+10</td>
                    <td>110</td>
                  </tr>
                  <tr class={if @current_streak == 7, do: "bg-primary/20"}>
                    <td>7</td>
                    <td>+70</td>
                    <td>170</td>
                  </tr>
                  <tr class={if @current_streak == 30, do: "bg-primary/20"}>
                    <td>30</td>
                    <td>+300</td>
                    <td>400</td>
                  </tr>
                  <tr class={if @current_streak >= 50, do: "bg-primary/20"}>
                    <td>50+</td>
                    <td>+500 (max)</td>
                    <td>600</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
