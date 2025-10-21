defmodule ShardWeb.CharacterSelectionComponentTest do
  use ShardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Shard.UsersFixtures

  alias Shard.Characters
  alias Shard.Characters.Character

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

      assert html =~ "Choose Your Character"
      assert html =~ "You don't have any characters yet"
      assert html =~ "Create Your First Character"
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
      {view, _html} =
        live_isolated_component(ShardWeb.CharacterSelectionComponent,
          id: "character-selection",
          show: true,
          characters: [],
          current_user: user
        )

      # Initially should be in create mode (no characters)
      assert render(view) =~ "Create New Character"

      # Switch to select mode first
      view |> element("#character-selection") |> render_hook("switch_to_select_mode")
      assert render(view) =~ "You don't have any characters yet"

      # Then switch back to create mode
      view |> element("#character-selection") |> render_hook("switch_to_create_mode")
      assert render(view) =~ "Character Name"
      assert render(view) =~ "Class"
      assert render(view) =~ "Race"
    end

    test "validates character form on change", %{user: user} do
      {view, _html} =
        live_isolated_component(ShardWeb.CharacterSelectionComponent,
          id: "character-selection",
          show: true,
          characters: [],
          current_user: user
        )

      # Trigger validation with invalid data
      view
      |> element("#character-form")
      |> render_change(%{character: %{name: "", class: "", race: ""}})

      # Form should still be rendered (validation happens but doesn't prevent rendering)
      assert render(view) =~ "Character Name"
    end

    test "creates character successfully", %{user: user} do
      {view, _html} =
        live_isolated_component(ShardWeb.CharacterSelectionComponent,
          id: "character-selection",
          show: true,
          characters: [],
          current_user: user
        )

      # Submit valid character data
      view
      |> element("#character-form")
      |> render_submit(%{
        character: %{
          name: "New Hero",
          class: "mage",
          race: "elf",
          description: "A powerful mage"
        }
      })

      # Verify character was created
      characters = Characters.get_characters_by_user(user.id)
      assert length(characters) == 1
      assert hd(characters).name == "New Hero"
      assert hd(characters).class == "mage"
      assert hd(characters).race == "elf"
    end

    test "handles character selection", %{user: user} do
      {:ok, character} =
        Characters.create_character(%{
          name: "Existing Hero",
          class: "rogue",
          race: "halfling",
          user_id: user.id
        })

      {view, _html} =
        live_isolated_component(ShardWeb.CharacterSelectionComponent,
          id: "character-selection",
          show: true,
          characters: [character],
          current_user: user
        )

      # Select the character
      view
      |> element("#character-selection")
      |> render_hook("select_character", %{character_id: to_string(character.id)})

      # The component should send a message to the parent (tested via message assertion in integration tests)
    end

    test "handles cancel selection", %{user: user} do
      {view, _html} =
        live_isolated_component(ShardWeb.CharacterSelectionComponent,
          id: "character-selection",
          show: true,
          characters: [],
          current_user: user
        )

      # Cancel selection
      view
      |> element("#character-selection")
      |> render_hook("cancel_map_selection")

      # The component should send a cancel message to the parent
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

      {view, _html} =
        live_isolated_component(ShardWeb.CharacterSelectionComponent,
          id: "character-selection",
          show: true,
          characters: [character],
          current_user: user
        )

      # Should start in select mode when characters exist
      assert render(view) =~ "Choose Your Character"
      assert render(view) =~ "Test Character"

      # Switch to create mode
      view |> element("#character-selection") |> render_hook("switch_to_create_mode")
      assert render(view) =~ "Create New Character"
      assert render(view) =~ "Character Name"

      # Switch back to select mode
      view |> element("#character-selection") |> render_hook("switch_to_select_mode")
      assert render(view) =~ "Choose Your Character"
      assert render(view) =~ "Test Character"
    end

    test "handles character creation with invalid data", %{user: user} do
      {view, _html} =
        live_isolated_component(ShardWeb.CharacterSelectionComponent,
          id: "character-selection",
          show: true,
          characters: [],
          current_user: user
        )

      # Submit invalid character data (missing required fields)
      view
      |> element("#character-form")
      |> render_submit(%{character: %{name: "", class: "", race: ""}})

      # Form should still be rendered with errors
      assert render(view) =~ "Character Name"
      # The component should handle the error case and re-render the form
    end
  end
end
