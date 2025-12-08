defmodule ShardWeb.AdminLive.Spells do
  use ShardWeb, :live_view

  alias Shard.Spells
  alias Shard.Spells.Spells, as: Spell

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :spells, Spells.list_spells())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Spell")
    |> assign(:spell, Spells.get_spell!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Spell")
    |> assign(:spell, %Spell{})
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Show Spell")
    |> assign(:spell, Spells.get_spell!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Spells")
    |> assign(:spell, nil)
  end

  @impl true
  def handle_info({ShardWeb.AdminLive.SpellFormComponent, {:saved, spell}}, socket) do
    {:noreply, stream_insert(socket, :spells, spell)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    spell = Spells.get_spell!(id)
    {:ok, _} = Spells.delete_spell(spell)

    {:noreply, stream_delete(socket, :spells, spell)}
  end
end
