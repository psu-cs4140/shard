defmodule ShardWeb.AdminLive.CharacterFormComponentTest do
  use ShardWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shard.UsersFixtures

  alias Shard.Characters
  alias Shard.Characters.Character

  @valid_attrs %{
    name: "Test Character",
    level: 1,
    class: "warrior",
    race: "human",
    health: 100,
    mana: 50,
    strength: 10,
    dexterity: 10,
    intelligence: 10,
    constitution: 10,
    experience: 0,
    gold: 100,
    location: "Starting Town",
    description: "A test character",
    is_active: true
  }

  @invalid_attrs %{
    name: nil,
    level: nil,
    class: nil,
    race: nil,
    health: nil,
    mana: nil,
    strength: nil,
    dexterity: nil,
    intelligence: nil,
    constitution: nil,
    experience: nil,
    gold: nil,
    location: nil,
    description: nil,
    is_active: nil
  }

  defp create_character(_) do
    user = user_fixture()
    character = character_fixture(Map.put(@valid_attrs, :user_id, user.id))
    %{character: character, user: user}
  end

  defp character_fixture(attrs \\ %{}) do
    user = user_fixture()
    attrs = Map.put_new(attrs, :user_id, user.id)

    {:ok, character} =
      attrs
      |> Enum.into(@valid_attrs)
      |> Characters.create_character()

    character
  end

  describe "render" do
    setup [:create_character]

    test "displays form for new character", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, ShardWeb.AdminLive.CharacterFormComponent,
        session: %{
          "character" => %Character{},
          "title" => "New Character",
          "action" => :new,
          "patch" => "/admin/characters"
        }
      )

      assert has_element?(view, "form#character-form")
      assert has_element?(view, "input[name='character[name]']")
      assert has_element?(view, "input[name='character[level]']")
      assert has_element?(view, "select[name='character[class]']")
      assert has_element?(view, "select[name='character[race]']")
      assert has_element?(view, "input[name='character[health]']")
      assert has_element?(view, "input[name='character[mana]']")
      assert has_element?(view, "input[name='character[strength]']")
      assert has_element?(view, "input[name='character[dexterity]']")
      assert has_element?(view, "input[name='character[intelligence]']")
      assert has_element?(view, "input[name='character[constitution]']")
      assert has_element?(view, "input[name='character[experience]']")
      assert has_element?(view, "input[name='character[gold]']")
      assert has_element?(view, "input[name='character[location]']")
      assert has_element?(view, "textarea[name='character[description]']")
      assert has_element?(view, "select[name='character[user_id]']")
      assert has_element?(view, "input[name='character[is_active]']")
      assert has_element?(view, "button", "Save Character")
    end

    test "displays form for editing character", %{conn: conn, character: character} do
      {:ok, view, _html} = live_isolated(conn, ShardWeb.AdminLive.CharacterFormComponent,
        session: %{
          "character" => character,
          "title" => "Edit Character",
          "action" => :edit,
          "patch" => "/admin/characters"
        }
      )

      assert has_element?(view, "form#character-form")
      assert has_element?(view, "input[name='character[name]'][value='#{character.name}']")
      assert has_element?(view, "input[name='character[level]'][value='#{character.level}']")
    end

    test "displays class options", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, ShardWeb.AdminLive.CharacterFormComponent,
        session: %{
          "character" => %Character{},
          "title" => "New Character",
          "action" => :new,
          "patch" => "/admin/characters"
        }
      )

      assert has_element?(view, "option[value='warrior']", "Warrior")
      assert has_element?(view, "option[value='mage']", "Mage")
      assert has_element?(view, "option[value='rogue']", "Rogue")
      assert has_element?(view, "option[value='cleric']", "Cleric")
      assert has_element?(view, "option[value='ranger']", "Ranger")
    end

    test "displays race options", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, ShardWeb.AdminLive.CharacterFormComponent,
        session: %{
          "character" => %Character{},
          "title" => "New Character",
          "action" => :new,
          "patch" => "/admin/characters"
        }
      )

      assert has_element?(view, "option[value='human']", "Human")
      assert has_element?(view, "option[value='elf']", "Elf")
      assert has_element?(view, "option[value='dwarf']", "Dwarf")
      assert has_element?(view, "option[value='halfling']", "Halfling")
      assert has_element?(view, "option[value='orc']", "Orc")
    end
  end

  describe "validate" do
    test "validates character form with valid data", %{conn: conn} do
      user = user_fixture()
      
      {:ok, view, _html} = live_isolated(conn, ShardWeb.AdminLive.CharacterFormComponent,
        session: %{
          "character" => %Character{},
          "title" => "New Character",
          "action" => :new,
          "patch" => "/admin/characters"
        }
      )

      valid_params = Map.put(@valid_attrs, :user_id, user.id)

      assert view
             |> form("#character-form", character: valid_params)
             |> render_change() =~ "New Character"

      refute has_element?(view, ".invalid-feedback")
    end

    test "validates character form with invalid data", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, ShardWeb.AdminLive.CharacterFormComponent,
        session: %{
          "character" => %Character{},
          "title" => "New Character",
          "action" => :new,
          "patch" => "/admin/characters"
        }
      )

      assert view
             |> form("#character-form", character: @invalid_attrs)
             |> render_change() =~ "New Character"
    end
  end

  describe "save new character" do
    test "saves new character with valid data", %{conn: conn} do
      user = user_fixture()
      
      {:ok, view, _html} = live_isolated(conn, ShardWeb.AdminLive.CharacterFormComponent,
        session: %{
          "character" => %Character{},
          "title" => "New Character",
          "action" => :new,
          "patch" => "/admin/characters"
        }
      )

      valid_params = Map.put(@valid_attrs, :user_id, user.id)

      # Mock the parent process to receive the notification
      parent_pid = self()
      
      # Override the notify_parent function to send to our test process
      view
      |> form("#character-form", character: valid_params)
      |> render_submit()

      # Check that a character was created
      assert Characters.list_characters() |> length() > 0
    end

    test "does not save character with invalid data", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, ShardWeb.AdminLive.CharacterFormComponent,
        session: %{
          "character" => %Character{},
          "title" => "New Character",
          "action" => :new,
          "patch" => "/admin/characters"
        }
      )

      initial_count = Characters.list_characters() |> length()

      view
      |> form("#character-form", character: @invalid_attrs)
      |> render_submit()

      # Check that no character was created
      assert Characters.list_characters() |> length() == initial_count
    end
  end

  describe "save existing character" do
    setup [:create_character]

    test "updates character with valid data", %{conn: conn, character: character} do
      {:ok, view, _html} = live_isolated(conn, ShardWeb.AdminLive.CharacterFormComponent,
        session: %{
          "character" => character,
          "title" => "Edit Character",
          "action" => :edit,
          "patch" => "/admin/characters"
        }
      )

      updated_attrs = %{name: "Updated Character Name", level: 5}

      view
      |> form("#character-form", character: updated_attrs)
      |> render_submit()

      updated_character = Characters.get_character!(character.id)
      assert updated_character.name == "Updated Character Name"
      assert updated_character.level == 5
    end

    test "does not update character with invalid data", %{conn: conn, character: character} do
      {:ok, view, _html} = live_isolated(conn, ShardWeb.AdminLive.CharacterFormComponent,
        session: %{
          "character" => character,
          "title" => "Edit Character",
          "action" => :edit,
          "patch" => "/admin/characters"
        }
      )

      original_name = character.name

      view
      |> form("#character-form", character: %{name: nil})
      |> render_submit()

      unchanged_character = Characters.get_character!(character.id)
      assert unchanged_character.name == original_name
    end
  end

  describe "user options" do
    test "loads user options for select dropdown", %{conn: conn} do
      user1 = user_fixture(%{email: "user1@example.com"})
      user2 = user_fixture(%{email: "user2@example.com"})

      {:ok, view, html} = live_isolated(conn, ShardWeb.AdminLive.CharacterFormComponent,
        session: %{
          "character" => %Character{},
          "title" => "New Character",
          "action" => :new,
          "patch" => "/admin/characters"
        }
      )

      assert html =~ user1.email
      assert html =~ user2.email
      assert has_element?(view, "option[value='#{user1.id}']")
      assert has_element?(view, "option[value='#{user2.id}']")
    end
  end
end
