defmodule ShardWeb.AdminLive.Pets do
  use ShardWeb, :live_view

  alias Shard.Characters

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:characters, Characters.list_characters())
     |> assign(:pet_form, empty_pet_form())
     |> assign(:page_title, "Pet Management")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Pet Management")
  end

  @impl true
  def handle_event("grant_pet", %{"pet" => pet_params}, socket) do
    with {:ok, character_id} <- parse_character_id(pet_params["character_id"]),
         {:ok, level} <- parse_level(pet_params["level"]),
         %{} = character <- Characters.get_character(character_id),
         {:ok, updated_character} <- perform_pet_grant(character, pet_params["pet_action"], level) do
      {:noreply,
       socket
       |> put_flash(:info, pet_success_message(updated_character, pet_params["pet_action"]))
       |> refresh_pet_admin_form(character_id, level)}
    else
      nil ->
        {:noreply, put_flash(socket, :error, "Character not found.")}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  defp parse_character_id(nil), do: {:error, "Please select a character."}

  defp parse_character_id(value) do
    case Integer.parse(value) do
      {id, ""} when id > 0 -> {:ok, id}
      _ -> {:error, "Invalid character selected."}
    end
  end

  defp parse_level(value) do
    value = value || "1"

    case Integer.parse(value) do
      {level, ""} when level > 0 -> {:ok, level}
      _ -> {:error, "Level must be a positive integer."}
    end
  end

  defp perform_pet_grant(character, "pet_rock", level),
    do: Characters.grant_pet_rock(character, level)

  defp perform_pet_grant(character, "shroomling", level),
    do: Characters.grant_shroomling(character, level)

  defp perform_pet_grant(character, "both", level),
    do: Characters.grant_all_pets(character, level)

  defp perform_pet_grant(_character, _action, _level),
    do: {:error, "Please choose a valid pet action."}

  defp pet_success_message(character, "pet_rock"),
    do: "Granted Pet Rock to #{character.name}."

  defp pet_success_message(character, "shroomling"),
    do: "Granted Shroomling to #{character.name}."

  defp pet_success_message(character, _),
    do: "Granted both pets to #{character.name}."

  defp refresh_pet_admin_form(socket, character_id, level) do
    socket
    |> assign(:characters, Characters.list_characters())
    |> assign(:pet_form, pet_form(character_id, level))
  end

  defp empty_pet_form, do: pet_form("", 1)

  defp pet_form(character_id, level) do
    %{"character_id" => to_string(character_id), "level" => to_string(level)}
    |> Phoenix.Component.to_form(as: :pet)
  end
end
