defmodule Shard.RepoTest do
  use Shard.DataCase

  alias Shard.Repo

  test "repo is configured and accessible" do
    # Simple test to ensure repo is working
    assert Repo.query("SELECT 1") == {:ok, %Postgrex.Result{rows: [[1]]}}
  end
end
