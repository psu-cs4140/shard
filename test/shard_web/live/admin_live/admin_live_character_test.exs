defmodule ShardWeb.AdminLive.CharactersTest do
  use ShardWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shard.UsersFixtures
  import Shard.CharactersFixtures

  @create_attrs %{
    name: "Test Character",
    level: 1,
    experience: 0,
    health: 100,
    mana: 50
  }
  @update_attrs %{
    name: "Updated Character",
    level: 2,
    experience: 100,
    health: 120,
    mana: 60
  }
  @invalid_attrs %{name: nil, level: nil}

  defp create_character(_) do
    user = user_fixture()
    character = character_fixture(user_id: user.id)
    %{character: character, user: user}
  end

  defp create_admin_user(_) do
    admin = user_fixture(%{admin: true})
    %{admin: admin}
  end

  describe "Index" do
    setup [:create_admin_user, :create_character]

    test "lists all characters", %{conn: conn, admin: admin, character: character} do
      {:ok, _index_live, html} = 
        conn
        |> log_in_user(admin)
        |> live(~p"/admin/characters")

      assert html =~ "Characters"
      assert html =~ character.name
    end

    test "saves new character", %{conn: conn, admin: admin} do
      {:ok, index_live, _html} = 
        conn
        |> log_in_user(admin)
        |> live(~p"/admin/characters")

      assert index_live |> element("a", "New Character") |> render_click() =~
               "New Character"

      assert_patch(index_live, ~p"/admin/characters/new")

      assert index_live
             |> form("#character-form", character: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#character-form", character: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/characters")

      html = render(index_live)
      assert html =~ "Character created successfully"
      assert html =~ "Test Character"
    end

    test "updates character in listing", %{conn: conn, admin: admin, character: character} do
      {:ok, index_live, _html} = 
        conn
        |> log_in_user(admin)
        |> live(~p"/admin/characters")

      assert index_live |> element("#characters-#{character.id} a", "Edit") |> render_click() =~
               "Edit Character"

      assert_patch(index_live, ~p"/admin/characters/#{character}/edit")

      assert index_live
             |> form("#character-form", character: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#character-form", character: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/characters")

      html = render(index_live)
      assert html =~ "Character updated successfully"
      assert html =~ "Updated Character"
    end

    test "deletes character in listing", %{conn: conn, admin: admin, character: character} do
      {:ok, index_live, _html} = 
        conn
        |> log_in_user(admin)
        |> live(~p"/admin/characters")

      assert index_live |> element("#characters-#{character.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#characters-#{character.id}")
    end

    test "redirects non-admin users", %{conn: conn} do
      user = user_fixture(%{admin: false})
      
      assert {:error, {:redirect, %{to: "/"}}} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/characters")
    end

    test "redirects unauthenticated users", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log_in"}}} = 
        conn
        |> live(~p"/admin/characters")
    end
  end

  describe "Show" do
    setup [:create_admin_user, :create_character]

    test "displays character", %{conn: conn, admin: admin, character: character} do
      {:ok, _show_live, html} = 
        conn
        |> log_in_user(admin)
        |> live(~p"/admin/characters/#{character}")

      assert html =~ "Show Character"
      assert html =~ character.name
    end

    test "updates character within modal", %{conn: conn, admin: admin, character: character} do
      {:ok, show_live, _html} = 
        conn
        |> log_in_user(admin)
        |> live(~p"/admin/characters/#{character}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Character"

      assert_patch(show_live, ~p"/admin/characters/#{character}/edit")

      assert show_live
             |> form("#character-form", character: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#character-form", character: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/characters/#{character}")

      html = render(show_live)
      assert html =~ "Character updated successfully"
      assert html =~ "Updated Character"
    end

    test "redirects non-admin users", %{conn: conn, character: character} do
      user = user_fixture(%{admin: false})
      
      assert {:error, {:redirect, %{to: "/"}}} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/characters/#{character}")
    end
  end

  describe "Character ordering and filtering" do
    setup [:create_admin_user]

    test "displays characters in ascending order by insertion date", %{conn: conn, admin: admin} do
      user = user_fixture()
      
      # Create characters with slight delay to ensure different timestamps
      character1 = character_fixture(user_id: user.id, name: "First Character")
      :timer.sleep(10)
      character2 = character_fixture(user_id: user.id, name: "Second Character")

      {:ok, _index_live, html} = 
        conn
        |> log_in_user(admin)
        |> live(~p"/admin/characters")

      # The first character should appear before the second in the listing
      # since they're ordered by ascending insertion date
      character1_pos = :binary.match(html, character1.name) |> elem(0)
      character2_pos = :binary.match(html, character2.name) |> elem(0)
      
      assert character1_pos < character2_pos
    end

    test "displays user information with characters", %{conn: conn, admin: admin} do
      user = user_fixture(%{email: "test@example.com"})
      character = character_fixture(user_id: user.id)

      {:ok, _index_live, html} = 
        conn
        |> log_in_user(admin)
        |> live(~p"/admin/characters")

      assert html =~ character.name
      assert html =~ user.email
    end
  end

  describe "Error handling" do
    setup [:create_admin_user]

    test "handles character not found", %{conn: conn, admin: admin} do
      assert_raise Ecto.NoResultsError, fn ->
        conn
        |> log_in_user(admin)
        |> live(~p"/admin/characters/999999")
      end
    end

    test "handles database errors gracefully during creation", %{conn: conn, admin: admin} do
      {:ok, index_live, _html} = 
        conn
        |> log_in_user(admin)
        |> live(~p"/admin/characters")

      assert index_live |> element("a", "New Character") |> render_click()

      # Try to create character with duplicate name if uniqueness constraint exists
      # or other validation that would cause database error
      attrs_with_long_name = %{@create_attrs | name: String.duplicate("a", 300)}

      assert index_live
             |> form("#character-form", character: attrs_with_long_name)
             |> render_submit()

      # Should stay on the form page and show error
      assert_patch(index_live, ~p"/admin/characters/new")
    end
  end
end
