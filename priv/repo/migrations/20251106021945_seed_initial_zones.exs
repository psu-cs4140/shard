# This migration file has been split into separate migrations:
# - 20251106021945_seed_bone_zone.exs (Bone Zone and Elven Forest)
# - 20251106021946_seed_vampire_castle.exs (Vampire Castle)
#
# This file is kept as a placeholder to maintain migration order.

defmodule Shard.Repo.Migrations.SeedInitialZones do
  use Ecto.Migration

  def change do
    # This migration has been split - see the individual zone migrations
    :ok
  end
end
