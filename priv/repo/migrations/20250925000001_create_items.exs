defmodule Shard.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    # This migration is now a no-op since the items table is created in the earlier migration
    # 20241121000001_add_item_stats_support.exs with all the necessary fields and indexes

    # If the table doesn't exist for some reason, we could add a fallback here,
    # but normally the earlier migration should handle everything
    :ok
  end
end
