ExUnit.start()

# Run seeds for test database to ensure damage types and effects are available
Shard.Seeds.DamageTypesSeeder.run()
Shard.Seeds.EffectsSeeder.run()

Ecto.Adapters.SQL.Sandbox.mode(Shard.Repo, :manual)
