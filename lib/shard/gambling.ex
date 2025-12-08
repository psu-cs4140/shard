defmodule Shard.Gambling do
  @moduledoc """
  Context for managing coin flip betting and gambling functionality.
  """

  import Ecto.Query
  alias Shard.Characters.Character
  alias Shard.Gambling.Bet
  alias Shard.Repo

  @doc """
  Creates a new bet for a character.
  Returns {:error, reason} if the character doesn't have enough gold.
  """
  def create_bet(attrs) do
    character_id = attrs["character_id"] || attrs[:character_id]
    amount = parse_amount(attrs["amount"] || attrs[:amount])

    with {:ok, amount} <- validate_amount(amount),
         character when not is_nil(character) <- Repo.get(Character, character_id),
         :ok <- validate_sufficient_gold(character, amount),
         {:ok, bet} <- insert_bet(attrs),
         {:ok, _character} <- deduct_gold(character, amount) do
      {:ok, bet}
    else
      {:error, reason} -> {:error, reason}
      nil -> {:error, :character_not_found}
    end
  end

  @doc """
  Get all bets for a specific flip_id.
  """
  def get_bets_for_flip(flip_id) do
    from(b in Bet,
      where: b.flip_id == ^flip_id and b.result == "pending",
      preload: [:character]
    )
    |> Repo.all()
  end

  @doc """
  Get bet history for a character.
  """
  def get_character_bets(character_id, limit \\ 10) do
    from(b in Bet,
      where: b.character_id == ^character_id,
      order_by: [desc: b.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Get pending bet for a character on the current flip.
  """
  def get_pending_bet(character_id, flip_id) do
    from(b in Bet,
      where: b.character_id == ^character_id and b.flip_id == ^flip_id and b.result == "pending"
    )
    |> Repo.one()
  end

  @doc """
  Process all bets for a completed flip.
  Returns statistics about the results.
  """
  def process_flip_results(flip_id, coin_result) do
    bets = get_bets_for_flip(flip_id)

    Repo.transaction(fn ->
      results =
        Enum.map(bets, fn bet ->
          process_single_bet(bet, coin_result)
        end)

      winners = Enum.count(results, fn {status, _} -> status == :won end)
      losers = Enum.count(results, fn {status, _} -> status == :lost end)

      %{
        total_bets: length(bets),
        winners: winners,
        losers: losers
      }
    end)
  end

  # Private functions

  defp parse_amount(amount) when is_integer(amount), do: amount

  defp parse_amount(amount) when is_binary(amount) do
    case Integer.parse(amount) do
      {num, _} -> num
      :error -> :error
    end
  end

  defp parse_amount(_), do: :error

  defp validate_amount(amount) when is_integer(amount) and amount > 0, do: {:ok, amount}
  defp validate_amount(:error), do: {:error, :invalid_amount}
  defp validate_amount(_), do: {:error, :invalid_amount}

  defp validate_sufficient_gold(%Character{gold: gold}, amount) when gold >= amount, do: :ok
  defp validate_sufficient_gold(_character, _amount), do: {:error, :insufficient_gold}

  defp insert_bet(attrs) do
    %Bet{}
    |> Bet.changeset(attrs)
    |> Repo.insert()
  end

  defp deduct_gold(character, amount) do
    character
    |> Character.changeset(%{gold: character.gold - amount})
    |> Repo.update()
  end

  defp process_single_bet(bet, coin_result) do
    won = bet.prediction == coin_result

    {result, payout} =
      if won do
        {"won", bet.amount * 2}
      else
        {"lost", 0}
      end

    # Update bet record
    bet
    |> Bet.changeset(%{result: result, payout: payout})
    |> Repo.update!()

    # If won, add payout to character's gold
    if won do
      character = Repo.get!(Character, bet.character_id)

      character
      |> Character.changeset(%{gold: character.gold + payout})
      |> Repo.update!()

      {:won, payout}
    else
      {:lost, 0}
    end
  end

  @doc """
  Get statistics for the gambling page.
  """
  def get_statistics(character_id) do
    total_bets =
      from(b in Bet, where: b.character_id == ^character_id, select: count(b.id))
      |> Repo.one() || 0

    total_won =
      from(b in Bet,
        where: b.character_id == ^character_id and b.result == "won",
        select: count(b.id)
      )
      |> Repo.one() || 0

    total_wagered =
      from(b in Bet,
        where: b.character_id == ^character_id,
        select: sum(b.amount)
      )
      |> Repo.one() || 0

    total_winnings =
      from(b in Bet,
        where: b.character_id == ^character_id and b.result == "won",
        select: sum(b.payout)
      )
      |> Repo.one() || 0

    %{
      total_bets: total_bets,
      total_won: total_won,
      total_wagered: total_wagered,
      total_winnings: total_winnings,
      win_rate: if(total_bets > 0, do: Float.round(total_won / total_bets * 100, 1), else: 0)
    }
  end
end
