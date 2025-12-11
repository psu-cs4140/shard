defmodule Shard.Titles.TitleTest do
  use Shard.DataCase

  alias Shard.Titles.Title

  @valid_attrs %{
    name: "Test Title",
    description: "A test title description",
    category: "achievement",
    rarity: "common",
    requirements: %{"level" => 5},
    color: "text-blue-500"
  }

  @invalid_attrs %{}

  describe "changeset/2" do
    test "valid changeset with all fields" do
      changeset = Title.changeset(%Title{}, @valid_attrs)
      assert changeset.valid?
    end

    test "invalid changeset with missing required fields" do
      changeset = Title.changeset(%Title{}, @invalid_attrs)
      refute changeset.valid?
      assert %{name: ["can't be blank"], rarity: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates name length" do
      attrs = Map.put(@valid_attrs, :name, String.duplicate("a", 51))
      changeset = Title.changeset(%Title{}, attrs)
      refute changeset.valid?
      assert %{name: ["should be at most 50 character(s)"]} = errors_on(changeset)
    end

    test "validates rarity inclusion" do
      attrs = Map.put(@valid_attrs, :rarity, "invalid_rarity")
      changeset = Title.changeset(%Title{}, attrs)
      refute changeset.valid?
      assert %{rarity: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts all valid rarities" do
      valid_rarities = ["common", "uncommon", "rare", "epic", "legendary"]

      for rarity <- valid_rarities do
        attrs = Map.put(@valid_attrs, :rarity, rarity)
        changeset = Title.changeset(%Title{}, attrs)
        assert changeset.valid?, "Expected #{rarity} to be valid"
      end
    end

    test "sets default color based on rarity when no color provided" do
      attrs = Map.delete(@valid_attrs, :color) |> Map.put(:rarity, "rare")
      changeset = Title.changeset(%Title{}, attrs)
      assert changeset.valid?
      # Test that the changeset is valid and the get_color_class function works
      title = Ecto.Changeset.apply_changes(changeset)
      color_class = Title.get_color_class(title)
      assert color_class == "text-blue-600"
    end

    test "preserves custom color when provided" do
      attrs = Map.put(@valid_attrs, :color, "text-custom-500")
      changeset = Title.changeset(%Title{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :color) == "text-custom-500"
    end

    test "validates requirements as map" do
      attrs = Map.put(@valid_attrs, :requirements, "invalid")
      changeset = Title.changeset(%Title{}, attrs)
      refute changeset.valid?
    end

    test "allows nil requirements" do
      attrs = Map.put(@valid_attrs, :requirements, nil)
      changeset = Title.changeset(%Title{}, attrs)
      assert changeset.valid?
    end

    test "allows empty map requirements" do
      attrs = Map.put(@valid_attrs, :requirements, %{})
      changeset = Title.changeset(%Title{}, attrs)
      assert changeset.valid?
    end
  end

  describe "get_color_class/1" do
    test "returns custom color when set" do
      title = %Title{color: "text-custom-500", rarity: "common"}
      assert Title.get_color_class(title) == "text-custom-500"
    end

    test "returns default color for common rarity" do
      title = %Title{color: nil, rarity: "common"}
      assert Title.get_color_class(title) == "text-gray-600"
    end

    test "returns default color for uncommon rarity" do
      title = %Title{color: nil, rarity: "uncommon"}
      assert Title.get_color_class(title) == "text-green-600"
    end

    test "returns default color for rare rarity" do
      title = %Title{color: nil, rarity: "rare"}
      assert Title.get_color_class(title) == "text-blue-600"
    end

    test "returns default color for epic rarity" do
      title = %Title{color: nil, rarity: "epic"}
      assert Title.get_color_class(title) == "text-purple-600"
    end

    test "returns default color for legendary rarity" do
      title = %Title{color: nil, rarity: "legendary"}
      assert Title.get_color_class(title) == "text-yellow-600"
    end
  end
end
