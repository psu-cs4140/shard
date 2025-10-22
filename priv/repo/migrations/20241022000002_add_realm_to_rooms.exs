defmodule Shard.Repo.Migrations.AddRealmToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :realm_id, references(:realms, on_delete: :nilify_all)
    end

    create index(:rooms, [:realm_id])
  end
end
