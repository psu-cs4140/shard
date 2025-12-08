defmodule Shard.Repo.Migrations.AddMiningFieldsToCharacters do
  use Ecto.Migration

  def change do
    unless column_exists?(:characters, :is_mining) do
      alter table(:characters) do
        add :is_mining, :boolean, default: false, null: false
      end
    end

    unless column_exists?(:characters, :mining_started_at) do
      alter table(:characters) do
        add :mining_started_at, :utc_datetime_usec, null: true
      end
    end

    unless column_exists?(:characters, :is_chopping) do
      alter table(:characters) do
        add :is_chopping, :boolean, default: false, null: false
      end
    end

    unless column_exists?(:characters, :chopping_started_at) do
      alter table(:characters) do
        add :chopping_started_at, :utc_datetime_usec, null: true
      end
    end
  end

  defp column_exists?(table, column) do
    query = """
    SELECT COUNT(*)
    FROM information_schema.columns
    WHERE table_name = $1 AND column_name = $2
    """

    params = [table |> to_string(), column |> to_string()]

    repo().query!(query, params).rows |> List.first() |> List.first() > 0
  end
end
