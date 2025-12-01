defmodule Shard.Repo.Migrations.CreateParties do
  use Ecto.Migration

  def change do
    create table(:parties) do
      add :name, :string
      add :leader_id, references(:users, on_delete: :delete_all), null: false
      add :max_size, :integer, default: 6

      timestamps(type: :utc_datetime)
    end

    create index(:parties, [:leader_id])

    create table(:party_members) do
      add :party_id, references(:parties, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :joined_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:party_members, [:party_id])
    create index(:party_members, [:user_id])
    create unique_index(:party_members, [:party_id, :user_id])
  end
end
