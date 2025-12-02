defmodule Shard.Users.UserZoneProgressTest do
  use Shard.DataCase

  alias Shard.Users.UserZoneProgress
  alias Shard.{Users, Map}

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      user = insert(:user)
      zone = insert(:zone)
      
      attrs = %{
        user_id: user.id,
        zone_id: zone.id,
        progress: "in_progress"
      }
      
      changeset = UserZoneProgress.changeset(%UserZoneProgress{}, attrs)
      assert changeset.valid?
    end

    test "invalid changeset with invalid progress state" do
      user = insert(:user)
      zone = insert(:zone)
      
      attrs = %{
        user_id: user.id,
        zone_id: zone.id,
        progress: "invalid_state"
      }
      
      changeset = UserZoneProgress.changeset(%UserZoneProgress{}, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).progress
    end

    test "requires all fields" do
      changeset = UserZoneProgress.changeset(%UserZoneProgress{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).progress
      assert "can't be blank" in errors_on(changeset).user_id
      assert "can't be blank" in errors_on(changeset).zone_id
    end
  end

  describe "initialize_for_user/2" do
    test "creates progress records for all zones" do
      user = insert(:user)
      zone1 = insert(:zone, name: "Zone 1")
      zone2 = insert(:zone, name: "Zone 2")
      
      UserZoneProgress.initialize_for_user(user.id)
      
      progress_records = UserZoneProgress.for_user(user.id)
      assert length(progress_records) == 2
      
      # All should be locked by default
      assert Enum.all?(progress_records, &(&1.progress == "locked"))
    end

    test "sets starter zones to in_progress" do
      user = insert(:user)
      starter_zone = insert(:zone, name: "Starter Zone")
      other_zone = insert(:zone, name: "Other Zone")
      
      UserZoneProgress.initialize_for_user(user.id, [starter_zone.id])
      
      progress_records = UserZoneProgress.for_user(user.id)
      starter_progress = Enum.find(progress_records, &(&1.zone_id == starter_zone.id))
      other_progress = Enum.find(progress_records, &(&1.zone_id == other_zone.id))
      
      assert starter_progress.progress == "in_progress"
      assert other_progress.progress == "locked"
    end
  end

  describe "update_progress/3" do
    test "updates existing progress record" do
      user = insert(:user)
      zone = insert(:zone)
      
      # Create initial progress
      UserZoneProgress.initialize_for_user(user.id)
      
      # Update progress
      {:ok, updated} = UserZoneProgress.update_progress(user.id, zone.id, "completed")
      assert updated.progress == "completed"
    end

    test "creates new progress record if none exists" do
      user = insert(:user)
      zone = insert(:zone)
      
      {:ok, created} = UserZoneProgress.update_progress(user.id, zone.id, "in_progress")
      assert created.progress == "in_progress"
      assert created.user_id == user.id
      assert created.zone_id == zone.id
    end
  end

  # Helper function to create test data
  defp insert(factory, attrs \\ %{}) do
    case factory do
      :user ->
        %Users.User{
          email: "test#{System.unique_integer()}@example.com",
          hashed_password: "hashed_password"
        }
        |> Users.User.changeset(attrs)
        |> Repo.insert!()
        
      :zone ->
        default_attrs = %{
          name: "Test Zone #{System.unique_integer()}",
          description: "A test zone"
        }
        
        %Map.Zone{}
        |> Map.Zone.changeset(Map.merge(default_attrs, attrs))
        |> Repo.insert!()
    end
  end
end
