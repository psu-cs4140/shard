defmodule Shard.Repo.Migrations.CreateTitlesAndBadges do
  use Ecto.Migration

  def change do
    # Create titles table
    create table(:titles) do
      add :name, :string, null: false
      add :description, :text, null: false
      add :category, :string, null: false
      add :rarity, :string, null: false
      add :requirements, :map, default: %{}
      add :is_active, :boolean, default: true, null: false
      add :color, :string
      add :prefix, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    # Create badges table
    create table(:badges) do
      add :name, :string, null: false
      add :description, :text, null: false
      add :category, :string, null: false
      add :rarity, :string, null: false
      add :icon, :string
      add :requirements, :map, default: %{}
      add :is_active, :boolean, default: true, null: false
      add :color, :string

      timestamps(type: :utc_datetime)
    end

    # Create character_titles junction table
    create table(:character_titles) do
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      add :title_id, references(:titles, on_delete: :delete_all), null: false
      add :earned_at, :utc_datetime, null: false
      add :is_active, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    # Create character_badges junction table
    create table(:character_badges) do
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      add :badge_id, references(:badges, on_delete: :delete_all), null: false
      add :earned_at, :utc_datetime, null: false
      add :is_active, :boolean, default: false, null: false
      add :display_order, :integer

      timestamps(type: :utc_datetime)
    end

    # Create indexes
    create unique_index(:titles, [:name])
    create index(:titles, [:category])
    create index(:titles, [:rarity])
    create index(:titles, [:is_active])

    create unique_index(:badges, [:name])
    create index(:badges, [:category])
    create index(:badges, [:rarity])
    create index(:badges, [:is_active])

    create unique_index(:character_titles, [:character_id, :title_id])
    create index(:character_titles, [:character_id])
    create index(:character_titles, [:title_id])
    create index(:character_titles, [:is_active])

    create unique_index(:character_badges, [:character_id, :badge_id])
    create index(:character_badges, [:character_id])
    create index(:character_badges, [:badge_id])
    create index(:character_badges, [:is_active])
    create index(:character_badges, [:display_order])
  end
end
