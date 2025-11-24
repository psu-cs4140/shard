defmodule Shard.Repo.Migrations.CreateMarketplaceListings do
  use Ecto.Migration

  def change do
    create table(:marketplace_listings) do
      add :price, :integer, null: false
      add :status, :string, default: "active", null: false
      add :sold_at, :utc_datetime
      add :cancelled_at, :utc_datetime

      add :seller_id, references(:users, on_delete: :delete_all), null: false
      add :buyer_id, references(:users, on_delete: :nilify_all)

      add :character_inventory_id, references(:character_inventories, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:marketplace_listings, [:seller_id])
    create index(:marketplace_listings, [:buyer_id])
    create index(:marketplace_listings, [:character_inventory_id])
    create index(:marketplace_listings, [:status])
    create index(:marketplace_listings, [:inserted_at])
  end
end
