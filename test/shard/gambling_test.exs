defmodule Shard.GamblingTest do
  use Shard.DataCase

  alias Shard.Gambling
  alias Shard.Gambling.Bet
  alias Shard.Characters.Character

  describe "create_bet/1" do
    setup do
      character = character_fixture()
      %{character: character}
    end

    test "creates a bet with valid attributes", %{character: character} do
      attrs = %{
        character_id: character.id,
        flip_id: "flip-123",
        amount: 50,
        prediction: "heads"
      }

      {:ok, bet} = Gambling.create_bet(attrs)
      assert bet.character_id == character.id
      assert bet.flip_id == "flip-123"
      assert bet.amount == 50
      assert bet.prediction == "heads"
      assert bet.result == "pending"

      # Verify gold was deducted
      updated_character = Repo.get!(Character, character.id)
      assert updated_character.gold == character.gold - 50
    end

    test "returns error when character doesn't have enough gold", %{character: character} do
      # Update character to have less gold
      {:ok, poor_character} = Shard.Characters.update_character(character, %{gold: 10})

      attrs = %{
        character_id: poor_character.id,
        flip_id: "flip-123",
        amount: 50,
        prediction: "heads"
      }

      assert {:error, :insufficient_gold} = Gambling.create_bet(attrs)
    end

    test "returns error with invalid amount" do
      attrs = %{
        character_id: 1,
        flip_id: "flip-123",
        amount: 0,
        prediction: "heads"
      }

      assert {:error, :invalid_amount} = Gambling.create_bet(attrs)
    end

    test "returns error when character not found" do
      attrs = %{
        character_id: 999999,
        flip_id: "flip-123",
        amount: 50,
        prediction: "heads"
      }

      assert {:error, :character_not_found} = Gambling.create_bet(attrs)
    end

    test "handles string amount", %{character: character} do
      attrs = %{
        character_id: character.id,
        flip_id: "flip-123",
        amount: "25",
        prediction: "tails"
      }

      {:ok, bet} = Gambling.create_bet(attrs)
      assert bet.amount == 25
    end

    test "returns error with invalid string amount", %{character: character} do
      attrs = %{
        character_id: character.id,
        flip_id: "flip-123",
        amount: "invalid",
        prediction: "heads"
      }

      assert {:error, :invalid_amount} = Gambling.create_bet(attrs)
    end
  end

  describe "get_bets_for_flip/1" do
    setup do
      character1 = character_fixture()
      character2 = character_fixture()
      flip_id = "flip-456"

      {:ok, bet1} = Gambling.create_bet(%{
        character_id: character1.id,
        flip_id: flip_id,
        amount: 25,
        prediction: "heads"
      })

      {:ok, bet2} = Gambling.create_bet(%{
        character_id: character2.id,
        flip_id: flip_id,
        amount: 30,
        prediction: "tails"
      })

      %{flip_id: flip_id, bet1: bet1, bet2: bet2}
    end

    test "returns all bets for a flip", %{flip_id: flip_id, bet1: bet1, bet2: bet2} do
      bets = Gambling.get_bets_for_flip(flip_id)
      bet_ids = Enum.map(bets, & &1.id)

      assert length(bets) == 2
      assert bet1.id in bet_ids
      assert bet2.id in bet_ids
    end

    test "returns empty list for non-existent flip" do
      bets = Gambling.get_bets_for_flip("non-existent")
      assert bets == []
    end
  end

  describe "get_character_bets/2" do
    setup do
      character = character_fixture()

      # Create multiple bets
      {:ok, _bet1} = Gambling.create_bet(%{
        character_id: character.id,
        flip_id: "flip-1",
        amount: 10,
        prediction: "heads"
      })

      {:ok, _bet2} = Gambling.create_bet(%{
        character_id: character.id,
        flip_id: "flip-2",
        amount: 20,
        prediction: "tails"
      })

      %{character: character}
    end

    test "returns character's bet history", %{character: character} do
      bets = Gambling.get_character_bets(character.id)
      assert length(bets) == 2
    end

    test "respects limit parameter", %{character: character} do
      bets = Gambling.get_character_bets(character.id, 1)
      assert length(bets) == 1
    end

    test "returns empty list for character with no bets" do
      other_character = character_fixture()
      bets = Gambling.get_character_bets(other_character.id)
      assert bets == []
    end
  end

  describe "get_pending_bet/2" do
    setup do
      character = character_fixture()
      flip_id = "flip-789"

      {:ok, bet} = Gambling.create_bet(%{
        character_id: character.id,
        flip_id: flip_id,
        amount: 15,
        prediction: "heads"
      })

      %{character: character, flip_id: flip_id, bet: bet}
    end

    test "returns pending bet for character and flip", %{character: character, flip_id: flip_id, bet: bet} do
      found_bet = Gambling.get_pending_bet(character.id, flip_id)
      assert found_bet.id == bet.id
    end

    test "returns nil when no pending bet exists", %{character: character} do
      bet = Gambling.get_pending_bet(character.id, "non-existent-flip")
      assert bet == nil
    end
  end

  describe "process_flip_results/2" do
    setup do
      character1 = character_fixture()
      character2 = character_fixture()
      flip_id = "flip-results"

      {:ok, _bet1} = Gambling.create_bet(%{
        character_id: character1.id,
        flip_id: flip_id,
        amount: 25,
        prediction: "heads"
      })

      {:ok, _bet2} = Gambling.create_bet(%{
        character_id: character2.id,
        flip_id: flip_id,
        amount: 30,
        prediction: "tails"
      })

      %{flip_id: flip_id, character1: character1, character2: character2}
    end

    test "processes winning and losing bets correctly", %{flip_id: flip_id, character1: character1, character2: character2} do
      original_gold1 = Repo.get!(Character, character1.id).gold
      original_gold2 = Repo.get!(Character, character2.id).gold

      {:ok, results} = Gambling.process_flip_results(flip_id, "heads")

      assert results.total_bets == 2
      assert results.winners == 1
      assert results.losers == 1

      # Check that winner got payout
      winner_character = Repo.get!(Character, character1.id)
      assert winner_character.gold == original_gold1 + 50  # 25 * 2

      # Check that loser's gold didn't change (already deducted when bet was placed)
      loser_character = Repo.get!(Character, character2.id)
      assert loser_character.gold == original_gold2
    end

    test "handles case with no bets" do
      {:ok, results} = Gambling.process_flip_results("empty-flip", "heads")

      assert results.total_bets == 0
      assert results.winners == 0
      assert results.losers == 0
    end
  end

  describe "get_statistics/1" do
    setup do
      character = character_fixture()

      # Create some bet history
      {:ok, bet1} = Gambling.create_bet(%{
        character_id: character.id,
        flip_id: "flip-1",
        amount: 20,
        prediction: "heads"
      })

      {:ok, bet2} = Gambling.create_bet(%{
        character_id: character.id,
        flip_id: "flip-2",
        amount: 30,
        prediction: "tails"
      })

      # Process one as won, one as lost
      bet1 |> Bet.changeset(%{result: "won", payout: 40}) |> Repo.update!()
      bet2 |> Bet.changeset(%{result: "lost", payout: 0}) |> Repo.update!()

      %{character: character}
    end

    test "returns correct statistics", %{character: character} do
      stats = Gambling.get_statistics(character.id)

      assert stats.total_bets == 2
      assert stats.total_won == 1
      assert stats.total_wagered == 50
      assert stats.total_winnings == 40
      assert stats.win_rate == 50.0
    end

    test "returns zero statistics for character with no bets" do
      other_character = character_fixture()
      stats = Gambling.get_statistics(other_character.id)

      assert stats.total_bets == 0
      assert stats.total_won == 0
      assert stats.total_wagered == 0
      assert stats.total_winnings == 0
      assert stats.win_rate == 0
    end
  end

  defp character_fixture(attrs \\ %{}) do
    user = user_fixture()

    attrs = Enum.into(attrs, %{
      name: "Test Character #{System.unique_integer([:positive])}",
      class: "warrior",
      race: "human",
      user_id: user.id,
      gold: 1000
    })

    {:ok, character} = Shard.Characters.create_character(attrs)
    character
  end

  defp user_fixture do
    unique_email = "user#{System.unique_integer([:positive])}@example.com"

    {:ok, user} = Shard.Users.register_user(%{
      email: unique_email,
      password: "password123password123"
    })

    user
  end
end
