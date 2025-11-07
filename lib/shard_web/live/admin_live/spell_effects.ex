defmodule ShardWeb.AdminLive.SpellEffects do
  use ShardWeb, :live_view

  alias Shard.Spells
  alias Shard.Spells.SpellEffects, as: SpellEffect

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :spell_effects, Spells.list_spell_effects())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Spell Effect")
    |> assign(:spell_effect, Spells.get_spell_effect!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Spell Effect")
    |> assign(:spell_effect, %SpellEffect{})
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Show Spell Effect")
    |> assign(:spell_effect, Spells.get_spell_effect!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Spell Effects")
    |> assign(:spell_effect, nil)
  end

  @impl true
  def handle_info({ShardWeb.AdminLive.SpellEffectFormComponent, {:saved, spell_effect}}, socket) do
    {:noreply, stream_insert(socket, :spell_effects, spell_effect)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    spell_effect = Spells.get_spell_effect!(id)
    {:ok, _} = Spells.delete_spell_effect(spell_effect)

    {:noreply, stream_delete(socket, :spell_effects, spell_effect)}
  end
end
