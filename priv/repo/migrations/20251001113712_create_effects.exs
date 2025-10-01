defmodule Shard.Repo.Migrations.CreateEffects do
  use Ecto.Migration

  def change do
    create table(:effects) do
      add :name, :string
      add :modifier_type, :string
      add :modifier_value, :integer
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:effects, [:user_id])
  end
end
