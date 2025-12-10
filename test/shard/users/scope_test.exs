defmodule Shard.Users.ScopeTest do
  use Shard.DataCase

  alias Shard.Users.{Scope, User}
  import Shard.UsersFixtures

  describe "for_user/1" do
    test "creates scope for valid user" do
      user = user_fixture()
      scope = Scope.for_user(user)
      
      assert %Scope{} = scope
      assert scope.user == user
    end

    test "returns nil for nil user" do
      assert Scope.for_user(nil) == nil
    end
  end
end
