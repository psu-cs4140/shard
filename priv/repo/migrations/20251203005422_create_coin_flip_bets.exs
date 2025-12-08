defmodule Shard.Repo.Migrations.CreateCoinFlipBets do
  use Ecto.Migration

  def change do
    create table(:coin_flip_bets) do
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      add :flip_id, :string, null: false
      add :amount, :integer, null: false
      add :prediction, :string, null: false
      add :result, :string, default: "pending"
      add :payout, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:coin_flip_bets, [:character_id])
    create index(:coin_flip_bets, [:flip_id])
    create index(:coin_flip_bets, [:result])
  end
end
