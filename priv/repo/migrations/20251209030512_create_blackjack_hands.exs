defmodule Shard.Repo.Migrations.CreateBlackjackHands do
  use Ecto.Migration

  def change do
    create table(:blackjack_hands) do
      add :blackjack_game_id, references(:blackjack_games, on_delete: :delete_all), null: false
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      add :position, :integer, null: false
      add :hand_cards, :jsonb
      add :bet_amount, :integer, default: 0
      add :status, :string, default: "betting"
      add :outcome, :string, default: "pending"
      add :payout, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:blackjack_hands, [:blackjack_game_id])
    create index(:blackjack_hands, [:character_id])
    create unique_index(:blackjack_hands, [:blackjack_game_id, :position])
    create unique_index(:blackjack_hands, [:blackjack_game_id, :character_id])
  end
end
