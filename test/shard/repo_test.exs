defmodule Shard.RepoTest do
  use Shard.DataCase

  alias Shard.Repo

  test "repo is configured correctly" do
    assert Repo.__adapter__() == Ecto.Adapters.Postgres
  end

  test "repo can perform basic operations" do
    # Test that we can query the repo
    assert is_list(Repo.all(Shard.Users.User))
  end
end
