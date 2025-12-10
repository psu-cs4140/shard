defmodule Shard.Users.UserZoneProgressTest do
  use Shard.DataCase

  alias Shard.Users.UserZoneProgress
  import Shard.UsersFixtures

  describe "for_user/1" do
    test "returns empty list for user with no progress" do
      user = user_fixture()
      progress = UserZoneProgress.for_user(user.id)
      
      assert is_list(progress)
      assert Enum.empty?(progress)
    end

    test "returns list for valid user_id" do
      user = user_fixture()
      progress = UserZoneProgress.for_user(user.id)
      
      assert is_list(progress)
    end
  end
end
