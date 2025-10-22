defmodule Shard.Repo.Migrations.AddRealmFieldsToDoors do
  use Ecto.Migration

  def change do
    alter table(:doors) do
      add :from_realm_id, references(:realms, on_delete: :nilify_all)
      add :to_realm_id, references(:realms, on_delete: :nilify_all)
    end

    create index(:doors, [:from_realm_id])
    create index(:doors, [:to_realm_id])
  end
end
