defmodule Shard.Map.ZoneTest do
  use Shard.DataCase

  alias Shard.Map.Zone

  describe "changeset/2" do
    test "validates that max_level is greater than or equal to min_level" do
      attrs = %{
        name: "Test Zone",
        slug: "test-zone",
        min_level: 10,
        max_level: 5
      }

      changeset = Zone.changeset(%Zone{}, attrs)

      assert changeset.valid? == false
      assert "must be greater than or equal to min_level" in errors_on(changeset).max_level
    end
  end
end
