defmodule Shard.Repo.Migrations.AddSellableToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :sellable, :boolean, default: true
    end
    
    create index(:items, [:sellable])
    
    # Set existing "Admin Zone Editing Stick" items to not sellable
    execute """
    UPDATE items 
    SET sellable = false 
    WHERE name = 'Admin Zone Editing Stick'
    """
  end
end
