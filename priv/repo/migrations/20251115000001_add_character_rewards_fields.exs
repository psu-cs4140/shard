defmodule Shard.Repo.Migrations.AddCharacterRewardsFields do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add_if_not_exists :experience, :integer, default: 0
      add_if_not_exists :gold, :integer, default: 0
      add_if_not_exists :level, :integer, default: 1
    end

    create_if_not_exists index(:characters, [:level])
    create_if_not_exists index(:characters, [:experience])
  end
end
