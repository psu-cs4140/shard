defmodule ShardWeb.PageController do
  use ShardWeb, :controller

  def home(conn, _params) do
    # Simulate federation data
    realms = [
      %{name: "Mystic Highlands", players: 42, status: :online},
      %{name: "Shadow Depths", players: 28, status: :online},
      %{name: "Crystal Caverns", players: 15, status: :syncing}
    ]
    
    recent_events = [
      "🏰 New realm 'Mystic Highlands' has joined the federation",
      "⚔️ Epic battle concluded in Shadow Depths - 15 players participated",
      "💎 Rare artifact discovered in Crystal Caverns",
      "🌟 Player 'DragonSlayer' achieved level 50 across all realms"
    ]
    
    render(conn, :home, realms: realms, recent_events: recent_events)
  end
end
