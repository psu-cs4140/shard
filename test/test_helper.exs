ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Shard.Repo, :manual)

# Load test fixtures
Code.require_file("test/support/fixtures/characters_fixtures.ex")
