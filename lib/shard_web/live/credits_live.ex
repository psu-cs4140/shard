defmodule ShardWeb.CreditsLive do
  use ShardWeb, :live_view
  import Ecto.Query, only: [from: 2]
  alias Shard.{Repo}
  alias Shard.Map.Room
  alias Shard.Music

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, tracks: tracks_in_use())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto space-y-6">
      <h1 class="text-2xl font-semibold">Credits</h1>

      <section class="space-y-2">
        <h2 class="text-xl font-medium">Music</h2>

        <%= if @tracks == [] do %>
          <p class="text-base-content/70">No background music is in use.</p>
        <% else %>
          <ul class="list-disc pl-6 space-y-2">
            <%= for t <- @tracks do %>
              <li>
                <span class="font-medium">{display_title(t)}</span>
                {if t[:artist], do: " — #{t.artist}"}
                {if t[:source], do: " (#{t.source})"}
                {if t[:license], do: " — #{t.license}"}
              </li>
            <% end %>
          </ul>
        <% end %>
      </section>

      <p class="text-sm text-base-content/60">
        Keep <code>CREDITS.txt</code> updated per course policy.
      </p>
    </div>
    """
  end

  defp tracks_in_use do
    keys =
      Repo.all(
        from r in Room,
          where: not is_nil(r.music_key) and r.music_key != "",
          select: r.music_key,
          distinct: true
      )

    keys
    |> Enum.map(&Music.get/1)
    |> Enum.filter(& &1)
  end

  defp display_title(%{title: t}) when is_binary(t) and t != "", do: t
  defp display_title(%{url: "/audio/" <> rest}), do: rest
  defp display_title(_), do: "Unknown track"
end
