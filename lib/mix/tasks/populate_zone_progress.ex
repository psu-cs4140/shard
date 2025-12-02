defmodule Mix.Tasks.PopulateZoneProgress do
  @moduledoc """
  Populates zone progress for existing users.

  Run with: mix populate_zone_progress
  """
  use Mix.Task

  alias Shard.{Repo, Users}
  alias Shard.Users.{User, UserZoneProgress}
  alias Shard.Map.Zone

  @shortdoc "Populates zone progress for existing users"

  def run(_args) do
    Mix.Task.run("app.start")

    users = Repo.all(User)
    zones = Repo.all(Zone)

    IO.puts("Populating zone progress for #{length(users)} users and #{length(zones)} zones...")

    Enum.each(users, fn user ->
      Enum.each(zones, fn zone ->
        case Users.get_user_zone_progress(user.id, zone.id) do
          nil ->
            progress = if zone.display_order == 0, do: "in_progress", else: "locked"

            %UserZoneProgress{}
            |> UserZoneProgress.changeset(%{
              user_id: user.id,
              zone_id: zone.id,
              progress: progress
            })
            |> Repo.insert()

            IO.puts("Created progress record for user #{user.id}, zone #{zone.name}")

          _existing ->
            IO.puts("Progress already exists for user #{user.id}, zone #{zone.name}")
        end
      end)
    end)

    IO.puts("Zone progress population complete!")
  end
end
