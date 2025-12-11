defmodule Shard.Titles.BadgeTest do
  use Shard.DataCase

  alias Shard.Titles.Badge

  @valid_attrs %{
    name: "Test Badge",
    description: "A test badge description",
    category: "achievement",
    rarity: "common",
    requirements: %{"kills" => 10},
    icon: "sword",
    color: "text-blue-500"
  }

  @invalid_attrs %{}

  describe "changeset/2" do
    test "valid changeset with all fields" do
      changeset = Badge.changeset(%Badge{}, @valid_attrs)
      assert changeset.valid?
    end

    test "invalid changeset with missing required fields" do
      changeset = Badge.changeset(%Badge{}, @invalid_attrs)
      refute changeset.valid?
      assert %{name: ["can't be blank"], rarity: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates name length" do
      attrs = Map.put(@valid_attrs, :name, String.duplicate("a", 256))
      changeset = Badge.changeset(%Badge{}, attrs)
      refute changeset.valid?
      assert %{name: ["should be at most 255 character(s)"]} = errors_on(changeset)
    end

    test "validates rarity inclusion" do
      attrs = Map.put(@valid_attrs, :rarity, "invalid_rarity")
      changeset = Badge.changeset(%Badge{}, attrs)
      refute changeset.valid?
      assert %{rarity: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts all valid rarities" do
      valid_rarities = ["common", "uncommon", "rare", "epic", "legendary"]
      
      for rarity <- valid_rarities do
        attrs = Map.put(@valid_attrs, :rarity, rarity)
        changeset = Badge.changeset(%Badge{}, attrs)
        assert changeset.valid?, "Expected #{rarity} to be valid"
      end
    end

    test "sets default color based on rarity when no color provided" do
      attrs = Map.delete(@valid_attrs, :color) |> Map.put(:rarity, "epic")
      changeset = Badge.changeset(%Badge{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :color) == "text-purple-600"
    end

    test "preserves custom color when provided" do
      attrs = Map.put(@valid_attrs, :color, "text-custom-500")
      changeset = Badge.changeset(%Badge{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :color) == "text-custom-500"
    end

    test "validates requirements as map" do
      attrs = Map.put(@valid_attrs, :requirements, "invalid")
      changeset = Badge.changeset(%Badge{}, attrs)
      refute changeset.valid?
    end

    test "allows nil requirements" do
      attrs = Map.put(@valid_attrs, :requirements, nil)
      changeset = Badge.changeset(%Badge{}, attrs)
      assert changeset.valid?
    end

    test "allows empty map requirements" do
      attrs = Map.put(@valid_attrs, :requirements, %{})
      changeset = Badge.changeset(%Badge{}, attrs)
      assert changeset.valid?
    end

    test "validates icon length when provided" do
      attrs = Map.put(@valid_attrs, :icon, String.duplicate("a", 101))
      changeset = Badge.changeset(%Badge{}, attrs)
      refute changeset.valid?
      assert %{icon: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "allows nil icon" do
      attrs = Map.put(@valid_attrs, :icon, nil)
      changeset = Badge.changeset(%Badge{}, attrs)
      assert changeset.valid?
    end

    test "allows empty string icon" do
      attrs = Map.put(@valid_attrs, :icon, "")
      changeset = Badge.changeset(%Badge{}, attrs)
      assert changeset.valid?
    end
  end

  describe "get_color_class/1" do
    test "returns custom color when set" do
      badge = %Badge{color: "text-custom-500", rarity: "common"}
      assert Badge.get_color_class(badge) == "text-custom-500"
    end

    test "returns default color for common rarity" do
      badge = %Badge{color: nil, rarity: "common"}
      assert Badge.get_color_class(badge) == "text-gray-600"
    end

    test "returns default color for uncommon rarity" do
      badge = %Badge{color: nil, rarity: "uncommon"}
      assert Badge.get_color_class(badge) == "text-green-600"
    end

    test "returns default color for rare rarity" do
      badge = %Badge{color: nil, rarity: "rare"}
      assert Badge.get_color_class(badge) == "text-blue-600"
    end

    test "returns default color for epic rarity" do
      badge = %Badge{color: nil, rarity: "epic"}
      assert Badge.get_color_class(badge) == "text-purple-600"
    end

    test "returns default color for legendary rarity" do
      badge = %Badge{color: nil, rarity: "legendary"}
      assert Badge.get_color_class(badge) == "text-yellow-600"
    end
  end
end
