defmodule Shard.Social.PartyMemberTest do
  use Shard.DataCase

  alias Shard.Social.PartyMember

  test "module exists and is accessible" do
    assert Code.ensure_loaded?(PartyMember)
  end
end
