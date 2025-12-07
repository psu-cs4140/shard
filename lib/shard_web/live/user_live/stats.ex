defmodule ShardWeb.UserLive.Stats do
  use ShardWeb, :live_view

  alias Shard.{Users, Characters}

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    characters = Characters.list_characters_for_user(user.id)
    
    stats = %{
      total_playtime: format_playtime(user.total_playtime_seconds || 0),
      last_login: format_last_login(user.last_login_at),
      login_count: user.login_count || 0,
      account_created: format_date(user.inserted_at),
      character_count: length(characters),
      total_levels: Enum.sum(Enum.map(characters, & &1.level)),
      highest_level_character: get_highest_level_character(characters)
    }

    {:ok, assign(socket, stats: stats, characters: characters)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-6">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-primary mb-2">Player Statistics</h1>
        <p class="text-base-content/70">Your gaming journey at a glance</p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        <!-- Playtime Card -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title text-primary">
              <.icon name="hero-clock" class="w-6 h-6" />
              Total Playtime
            </h2>
            <p class="text-2xl font-bold"><%= @stats.total_playtime %></p>
          </div>
        </div>

        <!-- Login Stats Card -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title text-secondary">
              <.icon name="hero-user-circle" class="w-6 h-6" />
              Login Stats
            </h2>
            <p class="text-lg">Total Logins: <span class="font-bold"><%= @stats.login_count %></span></p>
            <p class="text-sm text-base-content/70">Last Login: <%= @stats.last_login %></p>
          </div>
        </div>

        <!-- Account Info Card -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title text-accent">
              <.icon name="hero-calendar-days" class="w-6 h-6" />
              Account Info
            </h2>
            <p class="text-lg">Member Since: <span class="font-bold"><%= @stats.account_created %></span></p>
          </div>
        </div>

        <!-- Character Stats Card -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title text-warning">
              <.icon name="hero-users" class="w-6 h-6" />
              Characters
            </h2>
            <p class="text-lg">Total Characters: <span class="font-bold"><%= @stats.character_count %></span></p>
            <p class="text-lg">Combined Levels: <span class="font-bold"><%= @stats.total_levels %></span></p>
            <%= if @stats.highest_level_character do %>
              <p class="text-sm text-base-content/70">
                Highest: <%= @stats.highest_level_character.name %> (Level <%= @stats.highest_level_character.level %>)
              </p>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Leaderboard Link -->
      <div class="mb-8 text-center">
        <.link navigate={~p"/leaderboard"} class="btn btn-primary btn-lg">
          <.icon name="hero-trophy" class="w-6 h-6" />
          View Leaderboard
        </.link>
      </div>

      <!-- Character List -->
      <%= if length(@characters) > 0 do %>
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title text-primary mb-4">Your Characters</h2>
            <div class="overflow-x-auto">
              <table class="table table-zebra">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Level</th>
                    <th>Class</th>
                    <th>Experience</th>
                    <th>Created</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for character <- @characters do %>
                    <tr>
                      <td class="font-semibold"><%= character.name %></td>
                      <td><%= character.level %></td>
                      <td><%= character.class %></td>
                      <td><%= character.experience %></td>
                      <td><%= format_date(character.inserted_at) %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      <% else %>
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body text-center">
            <h2 class="card-title justify-center text-base-content/70">No Characters Yet</h2>
            <p class="text-base-content/50">Create your first character to start your adventure!</p>
            <div class="card-actions justify-center mt-4">
              <.link navigate={~p"/characters/new"} class="btn btn-primary">
                Create Character
              </.link>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp format_playtime(seconds) when is_integer(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    remaining_seconds = rem(seconds, 60)

    cond do
      hours > 0 -> "#{hours}h #{minutes}m #{remaining_seconds}s"
      minutes > 0 -> "#{minutes}m #{remaining_seconds}s"
      true -> "#{remaining_seconds}s"
    end
  end

  defp format_playtime(_), do: "0s"

  defp format_last_login(nil), do: "Never"
  defp format_last_login(datetime) do
    datetime
    |> DateTime.to_date()
    |> Date.to_string()
  end

  defp format_date(datetime) do
    datetime
    |> DateTime.to_date()
    |> Date.to_string()
  end

  defp get_highest_level_character([]), do: nil
  defp get_highest_level_character(characters) do
    Enum.max_by(characters, & &1.level)
  end
end
