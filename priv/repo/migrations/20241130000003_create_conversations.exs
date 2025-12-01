defmodule Shard.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :name, :string
      add :type, :string, default: "direct", null: false

      timestamps(type: :utc_datetime)
    end

    create table(:conversation_participants) do
      add :conversation_id, references(:conversations, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :last_read_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:conversation_participants, [:conversation_id])
    create index(:conversation_participants, [:user_id])
    create unique_index(:conversation_participants, [:conversation_id, :user_id])

    create table(:messages) do
      add :conversation_id, references(:conversations, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :content, :text, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:conversation_id])
    create index(:messages, [:user_id])
    create index(:messages, [:inserted_at])
  end
end
