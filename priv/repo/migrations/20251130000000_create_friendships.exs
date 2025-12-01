defmodule Shard.Repo.Migrations.CreateFriendships do
  use Ecto.Migration

  def change do
    create table(:friendships, if_not_exists: true) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :friend_id, references(:users, on_delete: :delete_all), null: false
      add :status, :string, default: "pending", null: false

      timestamps(type: :utc_datetime)
    end

    create index(:friendships, [:user_id])
    create index(:friendships, [:friend_id])
    create unique_index(:friendships, [:user_id, :friend_id])

    # Ensure users can't friend themselves
    create constraint(:friendships, :no_self_friendship, check: "user_id != friend_id")
  end
end
