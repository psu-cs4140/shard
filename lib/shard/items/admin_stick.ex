defmodule Shard.Items.AdminStick do
  @moduledoc """
  Module for the Admin Stick item which allows admin players to modify zones.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo
  alias Shard.Items.Item

  @admin_stick_name "Admin Zone Editing Stick"

  @doc """
  Gets the Admin Stick item from the database by name.
  """
  def get_admin_stick_item do
    Repo.get_by(Item, name: @admin_stick_name)
  end

  @doc """
  Checks if an item is the Admin Stick.
  """
  def is_admin_stick?(%Item{name: name}) do
    name == @admin_stick_name
  end

  def is_admin_stick?(_), do: false
end
