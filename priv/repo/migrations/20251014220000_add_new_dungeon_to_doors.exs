defmodule Shard.Repo.Migrations.AddNewDungeonToDoors do
  use Ecto.Migration

  def change do
    unless column_exists?(:doors, :new_dungeon) do
      alter table(:doors) do
        add :new_dungeon, :boolean, default: false
      end
    end
  end

  defp column_exists?(table_name, column_name) do
    query = """
    SELECT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = $1 AND column_name = $2
    )
    """

    case Ecto.Adapters.SQL.query(Shard.Repo, query, [
           Atom.to_string(table_name),
           Atom.to_string(column_name)
         ]) do
      {:ok, %{rows: [[true]]}} -> true
      {:ok, %{rows: [[false]]}} -> false
      _ -> false
    end
  end
end
