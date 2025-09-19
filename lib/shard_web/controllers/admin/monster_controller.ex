defmodule ShardWeb.Admin.MonsterController do
  use ShardWeb, :controller

  alias Shard.World
  alias Shard.World.Monster

  def index(conn, _params) do
    monsters = World.list_monsters()
    render(conn, :index, monsters: monsters)
  end

  def new(conn, _params) do
    changeset = World.change_monster(%Monster{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"monster" => monster_params}) do
    case World.create_monster(monster_params) do
      {:ok, monster} ->
        conn
        |> put_flash(:info, "Monster created successfully.")
        |> redirect(to: ~p"/admin/monsters/#{monster}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    monster = World.get_monster!(id)
    render(conn, :show, monster: monster)
  end

  def edit(conn, %{"id" => id}) do
    monster = World.get_monster!(id)
    changeset = World.change_monster(monster)
    render(conn, :edit, monster: monster, changeset: changeset)
  end

  def update(conn, %{"id" => id, "monster" => monster_params}) do
    monster = World.get_monster!(id)

    case World.update_monster(monster, monster_params) do
      {:ok, monster} ->
        conn
        |> put_flash(:info, "Monster updated successfully.")
        |> redirect(to: ~p"/admin/monsters/#{monster}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, monster: monster, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    monster = World.get_monster!(id)
    {:ok, _monster} = World.delete_monster(monster)

    conn
    |> put_flash(:info, "Monster deleted successfully.")
    |> redirect(to: ~p"/admin/monsters")
  end
end
