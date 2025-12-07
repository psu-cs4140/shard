defmodule ShardWeb.UserLive.Leaderboard do
  use ShardWeb, :live_view

  alias Shard.Users

  @impl true
  def mount(_params, _session, socket) do
    leaderboard_data = Users.get_leaderboard("total_playtime_seconds", 50)
    
    {:ok, 
     assign(socket, 
       leaderboard_data: leaderboard_data,
       current_sort: "total_playtime_seconds",
       sort_options: [
         {"Total Playtime", "total_playtime_seconds"},
         {"Login Count", "login_count"},
         {"Account Age", "inserted_at"}
       ]
     )}
  end

  @impl true
  def handle_event("sort_by", %{"sort" => sort_field}, socket) do
    leaderboard_data = Users.get_leaderboard(sort_field, 50)
    
    {:noreply, 
     assign(socket, 
       leaderboard_data: leaderboard_data,
       current_sort: sort_field
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-6">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-primary mb-2">Player Leaderboard</h1>
        <p class="text-base-content/70">See how you stack up against other players</p>
      </div>

      <!-- Sort Controls -->
      <div class="mb-6">
        <div class="flex flex-wrap gap-2">
          <%= for {label, value} <- @sort_options do %>
            <button 
              phx-click="sort_by" 
              phx-value-sort={value}
              class={[
                "btn",
                if(@current_sort == value, do: "btn-primary", else: "btn-outline")
              ]}
            >
              <%= label %>
            </button>
          <% end %>
        </div>
      </div>

      <!-- Leaderboard Table -->
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <div class="overflow-x-auto">
            <table class="table table-zebra">
              <thead>
                <tr>
                  <th>Rank</th>
                  <th>Player</th>
                  <th>Total Playtime</th>
                  <th>Login Count</th>
                  <th>Characters</th>
                  <th>Total Levels</th>
                  <th>Highest Level</th>
                  <th>Zones Completed</th>
                  <th>Member Since</th>
                </tr>
              </thead>
              <tbody>
                <%= for {player_data, index} <- Enum.with_index(@leaderboard_data, 1) do %>
                  <tr class={if player_data.user.id == @current_scope.user.id, do: "bg-primary/10"}>
                    <td>
                      <div class="flex items-center gap-2">
                        <%= case index do %>
                          <% 1 -> %>
                            <span class="text-2xl">🥇</span>
                          <% 2 -> %>
                            <span class="text-2xl">🥈</span>
                          <% 3 -> %>
                            <span class="text-2xl">🥉</span>
                          <% _ -> %>
                            <span class="font-bold text-lg"><%= index %></span>
                        <% end %>
                      </div>
                    </td>
                    <td>
                      <div class="flex items-center gap-2">
                        <span class={[
                          "font-semibold",
                          if(player_data.user.id == @current_scope.user.id, do: "text-primary font-bold")
                        ]}>
                          <%= String.split(player_data.user.email, "@") |> hd() %>
                        </span>
                        <%= if player_data.user.id == @current_scope.user.id do %>
                          <span class="badge badge-primary badge-sm">You</span>
                        <% end %>
                        <%= if player_data.user.admin do %>
                          <span class="badge badge-warning badge-sm">Admin</span>
                        <% end %>
                      </div>
                    </td>
                    <td><%= format_playtime(player_data.user.total_playtime_seconds || 0) %></td>
                    <td><%= player_data.user.login_count || 0 %></td>
                    <td><%= player_data.character_count %></td>
                    <td><%= player_data.total_levels %></td>
                    <td><%= player_data.highest_level %></td>
                    <td><%= player_data.zones_completed %></td>
                    <td><%= format_date(player_data.user.inserted_at) %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Back to Stats -->
      <div class="mt-6">
        <.link navigate={~p"/stats"} class="btn btn-outline">
          <.icon name="hero-arrow-left" class="w-4 h-4" />
          Back to My Stats
        </.link>
      </div>
    </div>
    """
  end

  defp format_playtime(seconds) when is_integer(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    remaining_seconds = rem(seconds, 60)

    cond do
      hours > 0 -> "#{hours}h #{minutes}m"
      minutes > 0 -> "#{minutes}m #{remaining_seconds}s"
      true -> "#{remaining_seconds}s"
    end
  end

  defp format_playtime(_), do: "0s"

  defp format_date(datetime) do
    datetime
    |> DateTime.to_date()
    |> Date.to_string()
  end
end
