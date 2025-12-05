defmodule Shard.Users.ScopeTest do
  use ExUnit.Case, async: true

  alias Shard.Users.{Scope, User}

  describe "for_user/1" do
    test "creates scope for valid user" do
      user = %User{id: 1, email: "test@example.com"}
      scope = Scope.for_user(user)

      assert %Scope{user: ^user} = scope
      assert scope.user.id == 1
      assert scope.user.email == "test@example.com"
    end

    test "returns nil for nil user" do
      assert Scope.for_user(nil) == nil
    end
  end

  describe "struct fields" do
    test "has user field" do
      scope = %Scope{}
      assert Map.has_key?(scope, :user)
      assert scope.user == nil
    end

    test "can be created with user" do
      user = %User{id: 1}
      scope = %Scope{user: user}
      assert scope.user == user
    end
  end
end
