defmodule Shard.Social.PartyInvitationTest do
  use Shard.DataCase

  alias Shard.Social.PartyInvitation

  test "module exists and is accessible" do
    assert Code.ensure_loaded?(PartyInvitation)
  end
end
