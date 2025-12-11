defmodule Shard.RepoTest do
  use Shard.DataCase

  alias Shard.Repo

  test "repo is configured and accessible" do
    # Simple test to ensure repo is working
    {:ok, result} = Repo.query("SELECT 1")
    assert result.rows == [[1]]
  end
end
