defmodule Shard.Repo.Migrations.AddRealmFieldsToDoors do
  use Ecto.Migration

  def change do
    if table_exists?(:doors) do
      alter table(:doors) do
        add :from_realm_id, references(:realms, on_delete: :nilify_all)
        add :to_realm_id, references(:realms, on_delete: :nilify_all)
      end

      create index(:doors, [:from_realm_id])
      create index(:doors, [:to_realm_id])
    end
  end

  defp table_exists?(table_name) do
    query = "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = $1)"

    case Ecto.Adapters.SQL.query(Shard.Repo, query, [Atom.to_string(table_name)]) do
      {:ok, %{rows: [[true]]}} -> true
      {:ok, %{rows: [[false]]}} -> false
      _ -> false
    end
  end
end
