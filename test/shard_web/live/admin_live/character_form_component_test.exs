defmodule ShardWeb.AdminLive.CharacterFormComponentTest do
  use ShardWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shard.UsersFixtures
  import Shard.CharactersFixtures

  alias Shard.Characters.Character


  describe "render" do
    test "displays form for new character", %{conn: _conn} do
      html =
        render_component(ShardWeb.AdminLive.CharacterFormComponent,
          character: %Character{},
          title: "New Character",
          action: :new,
          patch: "/admin/characters",
          id: "new-character"
        )

      assert html =~ "form"
      assert html =~ "character[name]"
      assert html =~ "character[level]"
      assert html =~ "character[class]"
      assert html =~ "character[race]"
      assert html =~ "character[health]"
      assert html =~ "character[mana]"
      assert html =~ "character[strength]"
      assert html =~ "character[dexterity]"
      assert html =~ "character[intelligence]"
      assert html =~ "character[constitution]"
      assert html =~ "character[experience]"
      assert html =~ "character[gold]"
      assert html =~ "character[location]"
      assert html =~ "character[description]"
      assert html =~ "character[user_id]"
      assert html =~ "character[is_active]"
      assert html =~ "Save Character"
    end

    test "displays form for editing character", %{conn: _conn} do
      user = user_fixture()
      character = character_fixture(user_id: user.id)

      html =
        render_component(ShardWeb.AdminLive.CharacterFormComponent,
          character: character,
          title: "Edit Character",
          action: :edit,
          patch: "/admin/characters",
          id: "edit-character"
        )

      assert html =~ "form"
      assert html =~ character.name
      assert html =~ "#{character.level}"
    end

    test "displays class options", %{conn: _conn} do
      html =
        render_component(ShardWeb.AdminLive.CharacterFormComponent,
          character: %Character{},
          title: "New Character",
          action: :new,
          patch: "/admin/characters",
          id: "new-character"
        )

      assert html =~ "Warrior"
      assert html =~ "Mage"
      assert html =~ "Rogue"
      assert html =~ "Cleric"
      assert html =~ "Ranger"
    end

    test "displays race options", %{conn: _conn} do
      html =
        render_component(ShardWeb.AdminLive.CharacterFormComponent,
          character: %Character{},
          title: "New Character",
          action: :new,
          patch: "/admin/characters",
          id: "new-character"
        )

      assert html =~ "Human"
      assert html =~ "Elf"
      assert html =~ "Dwarf"
      assert html =~ "Halfling"
      assert html =~ "Orc"
    end
  end

  describe "user options" do
    test "loads user options for select dropdown", %{conn: _conn} do
      user1 = user_fixture(%{email: "user1@example.com"})
      user2 = user_fixture(%{email: "user2@example.com"})

      html =
        render_component(ShardWeb.AdminLive.CharacterFormComponent,
          character: %Character{},
          title: "New Character",
          action: :new,
          patch: "/admin/characters",
          id: "new-character"
        )

      assert html =~ user1.email
      assert html =~ user2.email
    end
  end
end
