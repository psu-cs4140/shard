defmodule Shard.Repo.Migrations.AddCurrentZoneToCharacters do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add :current_zone_id, references(:zones, on_delete: :nilify_all)
    end

    create index(:characters, [:current_zone_id])

    # Set default zone for existing characters (Legacy Map zone)
    execute(
      """
      UPDATE characters
      SET current_zone_id = (SELECT id FROM zones WHERE slug = 'legacy-map')
      WHERE current_zone_id IS NULL
      """,
      """
      UPDATE characters
      SET current_zone_id = NULL
      """
    )
  end
end
