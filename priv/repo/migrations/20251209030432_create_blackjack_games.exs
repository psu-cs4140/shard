defmodule Shard.Repo.Migrations.CreateBlackjackGames do
  use Ecto.Migration

  def change do
    create table(:blackjack_games) do
      add :game_id, :string, null: false
      add :status, :string, default: "waiting"
      add :dealer_hand, :jsonb
      add :current_player_index, :integer, default: 0
      add :round_started_at, :utc_datetime
      add :max_players, :integer, default: 6

      timestamps(type: :utc_datetime)
    end

    create unique_index(:blackjack_games, [:game_id])
    create index(:blackjack_games, [:status])
  end
end
