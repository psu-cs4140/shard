defmodule ShardWeb.CharacterLiveTest do
  use ShardWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shard.CharactersFixtures

  @create_attrs %{
    name: "some name",
    level: 42,
    description: "some description",
    location: "some location",
    class: "some class",
    race: "some race",
    health: 42,
    mana: 42,
    strength: 42,
    dexterity: 42,
    constitution: 42,
    experience: 42,
    gold: 42,
    is_active: true
  }
  @update_attrs %{
    name: "some updated name",
    level: 43,
    description: "some updated description",
    location: "some updated location",
    class: "some updated class",
    race: "some updated race",
    health: 43,
    mana: 43,
    strength: 43,
    dexterity: 43,
    constitution: 43,
    experience: 43,
    gold: 43,
    is_active: false
  }
  @invalid_attrs %{
    name: nil,
    level: nil,
    description: nil,
    location: nil,
    class: nil,
    race: nil,
    health: nil,
    mana: nil,
    strength: nil,
    dexterity: nil,
    constitution: nil,
    experience: nil,
    gold: nil,
    is_active: false
  }

  setup :register_and_log_in_user

  defp create_character(%{scope: scope}) do
    character = character_fixture(user: Map.get(scope, :user))

    %{character: character}
  end

  describe "Index" do
    setup [:create_character]

    test "lists all characters", %{conn: conn, character: character} do
      {:ok, _index_live, html} = live(conn, ~p"/characters")

      assert html =~ "Listing Characters"
      assert html =~ character.name
    end

    test "saves new character", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/characters")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Character")
               |> render_click()
               |> follow_redirect(conn, ~p"/characters/new")

      assert render(form_live) =~ "Create New Character"

      assert form_live
             |> form("#character-form", character: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#character-form", character: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/characters")

      html = render(index_live)
      assert html =~ "Character created successfully"
      assert html =~ "some name"
    end

    test "updates character in listing", %{conn: conn, character: character} do
      {:ok, index_live, _html} = live(conn, ~p"/characters")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#characters-#{character.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/characters/#{character}/edit")

      assert render(form_live) =~ "Edit Character"

      assert form_live
             |> form("#character-form", character: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#character-form", character: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/characters")

      html = render(index_live)
      assert html =~ "Character updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes character in listing", %{conn: conn, character: character} do
      {:ok, index_live, _html} = live(conn, ~p"/characters")

      assert index_live |> element("#characters-#{character.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#characters-#{character.id}")
    end
  end

  describe "Show" do
    setup [:create_character]

    test "displays character", %{conn: conn, character: character} do
      {:ok, _show_live, html} = live(conn, ~p"/characters/#{character}")

      assert html =~ "Show Character"
      assert html =~ character.name
    end

    test "updates character and returns to show", %{conn: conn, character: character} do
      {:ok, show_live, _html} = live(conn, ~p"/characters/#{character}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/characters/#{character}/edit?return_to=show")

      assert render(form_live) =~ "Edit Character"

      assert form_live
             |> form("#character-form", character: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#character-form", character: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/characters/#{character}")

      html = render(show_live)
      assert html =~ "Character updated successfully"
      assert html =~ "some updated name"
    end
  end
end
