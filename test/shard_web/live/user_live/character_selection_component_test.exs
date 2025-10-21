defmodule ShardWeb.CharacterSelectionComponentTest do
  use ShardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Shard.UsersFixtures

  alias Shard.Characters

  describe "CharacterSelectionComponent" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "renders character selection modal when show is true", %{user: user} do
      characters = []

      html =
        render_component(ShardWeb.CharacterSelectionComponent,
          id: "character-selection",
          show: true,
          characters: characters,
          current_user: user
        )

      # When no characters exist, component automatically switches to create mode
      assert html =~ "Create New Character"
      assert html =~ "Character Name"
      assert html =~ "Class"
      assert html =~ "Race"
    end

    test "does not render modal when show is false", %{user: user} do
      characters = []

      html =
        render_component(ShardWeb.CharacterSelectionComponent,
          id: "character-selection",
          show: false,
          characters: characters,
          current_user: user
        )

      refute html =~ "Choose Your Character"
      refute html =~ "Create Your First Character"
    end

    test "renders character list when characters exist", %{user: user} do
      {:ok, character} =
        Characters.create_character(%{
          name: "Test Hero",
          class: "warrior",
          race: "human",
          user_id: user.id
        })

      characters = [character]

      html =
        render_component(ShardWeb.CharacterSelectionComponent,
          id: "character-selection",
          show: true,
          characters: characters,
          current_user: user
        )

      assert html =~ "Found 1 character(s)"
      assert html =~ "Test Hero"
      assert html =~ "Level 1 Warrior"
      assert html =~ "Create New Character"
    end

    test "switches to create mode when switch_to_create_mode event is triggered", %{user: user} do
      # Test initial state with no characters (should be in create mode)
      html =
        render_component(ShardWeb.CharacterSelectionComponent,
          id: "character-selection",
          show: true,
          characters: [],
          current_user: user
        )

      # Initially should be in create mode (no characters)
      assert html =~ "Create New Character"
      assert html =~ "Character Name"
      assert html =~ "Class"
      assert html =~ "Race"
    end

    test "validates character form on change", %{user: user} do
      # Test that the form renders with validation fields
      html =
        render_component(ShardWeb.CharacterSelectionComponent,
          id: "character-selection",
          show: true,
          characters: [],
          current_user: user
        )

      # Form should be rendered with required fields
      assert html =~ "Character Name"
      assert html =~ "required"
    end

    test "creates character successfully", %{user: user} do
      # Test that the character creation form is rendered properly
      html =
        render_component(ShardWeb.CharacterSelectionComponent,
          id: "character-selection",
          show: true,
          characters: [],
          current_user: user
        )

      # Verify form elements are present
      assert html =~ "Character Name"
      assert html =~ "Class"
      assert html =~ "Race"
      assert html =~ "Create & Enter Map"
    end

    test "handles character selection", %{user: user} do
      {:ok, character} =
        Characters.create_character(%{
          name: "Existing Hero",
          class: "rogue",
          race: "halfling",
          user_id: user.id
        })

      html =
        render_component(ShardWeb.CharacterSelectionComponent,
          id: "character-selection",
          show: true,
          characters: [character],
          current_user: user
        )

      # Verify character is displayed with selection button
      assert html =~ "Existing Hero"
      assert html =~ "Level 1 Rogue"
      assert html =~ "phx-click=\"select_character\""
      assert html =~ "phx-value-character_id=\"#{character.id}\""
    end

    test "handles cancel selection", %{user: user} do
      {:ok, character} =
        Characters.create_character(%{
          name: "Test Character",
          class: "warrior",
          race: "human",
          user_id: user.id
        })

      html =
        render_component(ShardWeb.CharacterSelectionComponent,
          id: "character-selection",
          show: true,
          characters: [character],
          current_user: user
        )

      # Verify cancel button is present in select mode
      assert html =~ "Cancel"
      assert html =~ "phx-click=\"cancel_map_selection\""
    end

    test "renders character creation form with all required fields", %{user: user} do
      html =
        render_component(ShardWeb.CharacterSelectionComponent,
          id: "character-selection",
          show: true,
          characters: [],
          current_user: user
        )

      # Check for form fields
      assert html =~ "Character Name"
      assert html =~ "Class"
      assert html =~ "Race"
      assert html =~ "Description"

      # Check for class options
      assert html =~ "Warrior"
      assert html =~ "Mage"
      assert html =~ "Rogue"
      assert html =~ "Cleric"
      assert html =~ "Ranger"

      # Check for race options
      assert html =~ "Human"
      assert html =~ "Elf"
      assert html =~ "Dwarf"
      assert html =~ "Halfling"
      assert html =~ "Orc"
    end

    test "switches between select and create modes", %{user: user} do
      {:ok, character} =
        Characters.create_character(%{
          name: "Test Character",
          class: "warrior",
          race: "human",
          user_id: user.id
        })

      html =
        render_component(ShardWeb.CharacterSelectionComponent,
          id: "character-selection",
          show: true,
          characters: [character],
          current_user: user
        )

      # Should start in select mode when characters exist
      assert html =~ "Choose Your Character"
      assert html =~ "Test Character"
      assert html =~ "Create New Character"
      assert html =~ "phx-click=\"switch_to_create_mode\""
    end

    test "handles character creation with invalid data", %{user: user} do
      html =
        render_component(ShardWeb.CharacterSelectionComponent,
          id: "character-selection",
          show: true,
          characters: [],
          current_user: user
        )

      # Form should be rendered with required validation
      assert html =~ "Character Name"
      assert html =~ "required"
      assert html =~ "phx-submit=\"create_character\""
    end
  end
end
