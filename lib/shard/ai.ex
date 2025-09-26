defmodule Shard.AI do
  @moduledoc """
  The AI context for interacting with external AI services.
  """

  def generate_room_description(zone_description, surrounding_rooms) do
    prompt = """
    Generate a description for a room in a MUD game.

    Zone Description:
    #{zone_description}

    Surrounding Rooms:
    #{Enum.map_join(surrounding_rooms, "\n", &"- #{&1.name}: #{&1.description}")}

    Based on the above information, generate a creative and descriptive text for the room.
    """


    IO.inspect(prompt, label: "Prompt sent to grok (free model !!!)")

    api_key = Application.get_env(:shard, :open_router)[:api_key]
    IO.inspect(api_key, label: "API Key used (hehe)")


    headers = [
      {"Authorization", "Bearer #{Application.get_env(:shard, :open_router)[:api_key]}"},
      {"Content-Type", "application/json"}
    ]

    body = %{
      "model" => Application.get_env(:shard, :open_router)[:model],
      "messages" => [%{"role" => "user", "content" => prompt}]
    }

    response = Req.post("https://openrouter.ai/api/v1/chat/completions", headers: headers, json: body)
    IO.inspect(response, label: "OpenRouter AI Response")

    case response do
      {:ok, %{status: 200, body: %{"choices" => [%{"message" => %{"content" => description}}]}}} ->
        {:ok, String.trim(description)}

      {:ok, response} ->
        {:error, "Unexpected response from OpenRouter: #{inspect(response.body)}"}

      {:error, reason} ->
        {:error, "Failed to connect to OpenRouter: #{inspect(reason)}"}
    end
  end
end