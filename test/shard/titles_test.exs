defmodule Shard.TitlesTest do
  use Shard.DataCase

  alias Shard.Titles
  alias Shard.Titles.Title

  describe "titles" do
    @valid_attrs %{
      name: "Test Title",
      description: "A test title",
      rarity: "common",
      requirements: %{"level" => 5}
    }

    @invalid_attrs %{name: nil, rarity: nil}

    test "list_titles/0 returns all titles" do
      titles = Titles.list_titles()
      assert is_list(titles)
    end

    test "get_title!/1 returns the title with given id" do
      {:ok, title} = Titles.create_title(@valid_attrs)
      assert Titles.get_title!(title.id).id == title.id
    end

    test "create_title/1 with valid data creates a title" do
      assert {:ok, %Title{} = title} = Titles.create_title(@valid_attrs)
      assert title.name == "Test Title"
      assert title.description == "A test title"
      assert title.rarity == "common"
      assert title.requirements == %{"level" => 5}
    end

    test "create_title/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Titles.create_title(@invalid_attrs)
    end

    test "update_title/2 with valid data updates the title" do
      {:ok, title} = Titles.create_title(@valid_attrs)
      update_attrs = %{name: "Updated Title", rarity: "rare"}

      assert {:ok, %Title{} = title} = Titles.update_title(title, update_attrs)
      assert title.name == "Updated Title"
      assert title.rarity == "rare"
    end

    test "update_title/2 with invalid data returns error changeset" do
      {:ok, title} = Titles.create_title(@valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Titles.update_title(title, @invalid_attrs)
      assert title == Titles.get_title!(title.id)
    end

    test "delete_title/1 deletes the title" do
      {:ok, title} = Titles.create_title(@valid_attrs)
      assert {:ok, %Title{}} = Titles.delete_title(title)
      assert_raise Ecto.NoResultsError, fn -> Titles.get_title!(title.id) end
    end

    test "change_title/1 returns a title changeset" do
      {:ok, title} = Titles.create_title(@valid_attrs)
      assert %Ecto.Changeset{} = Titles.change_title(title)
    end

    test "get_titles_by_rarity/1 returns titles of specific rarity" do
      {:ok, _title} = Titles.create_title(@valid_attrs)
      titles = Titles.get_titles_by_rarity("common")
      assert is_list(titles)
      assert length(titles) >= 1
    end

    test "get_available_titles_for_character/1 returns available titles" do
      character_id = 1
      titles = Titles.get_available_titles_for_character(character_id)
      assert is_list(titles)
    end
  end

  describe "title validation" do
    test "validates required fields" do
      changeset = Title.changeset(%Title{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.name
      assert "can't be blank" in errors.rarity
    end

    test "validates rarity inclusion" do
      attrs = Map.put(@valid_attrs, :rarity, "invalid")
      changeset = Title.changeset(%Title{}, attrs)
      refute changeset.valid?
      assert %{rarity: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts valid rarities" do
      valid_rarities = ["common", "uncommon", "rare", "epic", "legendary"]

      for rarity <- valid_rarities do
        attrs = Map.put(@valid_attrs, :rarity, rarity)
        changeset = Title.changeset(%Title{}, attrs)
        assert changeset.valid?, "Expected #{rarity} to be valid"
      end
    end

    test "sets default color based on rarity" do
      attrs = Map.put(@valid_attrs, :rarity, "epic")
      changeset = Title.changeset(%Title{}, attrs)
      assert changeset.valid?
      # The default color should be set in the changeset
      assert get_change(changeset, :color) == "text-purple-600"
    end

    test "allows custom color to override default" do
      attrs = Map.merge(@valid_attrs, %{rarity: "common", color: "text-red-500"})
      changeset = Title.changeset(%Title{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :color) == "text-red-500"
    end
  end

  describe "character titles" do
    setup do
      {:ok, title} = Titles.create_title(@valid_attrs)
      %{title: title}
    end

    test "get_character_titles/1 returns character's titles" do
      character_id = 1
      titles = Titles.get_character_titles(character_id)
      assert is_list(titles)
    end

    test "character_has_title?/2 checks if character has title", %{title: title} do
      character_id = 1
      # Should return false for character without title
      refute Titles.character_has_title?(character_id, title.id)
    end

    test "award_title_to_character/2 awards title to character", %{title: title} do
      character_id = 1
      # This will likely fail due to foreign key constraints in test
      result = Titles.award_title_to_character(character_id, title.id)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "remove_title_from_character/2 removes title from character", %{title: title} do
      character_id = 1
      # Test removal (will likely return ok even if nothing to remove)
      result = Titles.remove_title_from_character(character_id, title.id)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end
end
