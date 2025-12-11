ExUnit.start()

# Run seeds for test database to ensure damage types and effects are available
Shard.Weapons.SeedData.DamageTypesSeeds.run()
Shard.Weapons.SeedData.EffectsSeeds.run()

Ecto.Adapters.SQL.Sandbox.mode(Shard.Repo, :manual)
