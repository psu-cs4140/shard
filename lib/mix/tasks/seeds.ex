defmodule Mix.Tasks.Seeds do
  @moduledoc """
  This module defines a mix task to run all seed files.
  """

  use Mix.Task

  @shortdoc "Run all seed files"
  def run(_) do
    Mix.Task.run("app.start")

    IO.puts("Running Damage Types Seeder...")
    Shard.Seeds.DamageTypesSeeder.run()
    IO.puts("Damage Types Seeder completed.")

    IO.puts("Running Effects Seeder...")
    Shard.Seeds.EffectsSeeder.run()
    IO.puts("Effects Seeder completed.")
  end
end
