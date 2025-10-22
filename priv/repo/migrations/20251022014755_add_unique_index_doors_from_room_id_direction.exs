defmodule Shard.Repo.Migrations.AddUniqueIndexDoorsFromRoomIdDirection do
  use Ecto.Migration

  def change do
    unless index_exists?(:doors, [:from_room_id, :direction]) do
      create unique_index(:doors, [:from_room_id, :direction])
    end
  end

  defp index_exists?(table_name, columns) do
    # Query to check if the index exists
    query = """
    SELECT 1 FROM pg_indexes
    WHERE tablename = $1
    AND indexdef LIKE '%' || $2 || '%'
    """

    case Ecto.Adapters.SQL.query(Shard.Repo, query, [
           Atom.to_string(table_name),
           Enum.join(columns, "_")
         ]) do
      {:ok, %{rows: [[_]]}} -> true
      _ -> false
    end
  end
end
