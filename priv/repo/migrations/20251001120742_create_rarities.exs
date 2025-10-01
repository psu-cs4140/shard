defmodule Shard.Repo.Migrations.CreateRarities do
  use Ecto.Migration

  def change do
    create table(:rarities) do
      add :name, :string


      timestamps(type: :utc_datetime)
    end


  end
end
