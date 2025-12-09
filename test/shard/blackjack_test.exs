defmodule Shard.BlackjackTest do
  use Shard.DataCase

  alias Shard.Gambling.Blackjack
  alias Shard.Gambling.BlackjackGame
  alias Shard.Gambling.BlackjackHand
  alias Shard.Characters
  alias Shard.Users

  describe "blackjack logic" do
    test "calculate_hand_value/1 calculates correct values" do
      # Test basic cards
      cards = [%{rank: "5", suit: "hearts"}, %{rank: "7", suit: "clubs"}]
      assert {12, false} = Blackjack.calculate_hand_value(cards)

      # Test face cards
      cards = [%{rank: "K", suit: "hearts"}, %{rank: "Q", suit: "clubs"}]
      assert {20, false} = Blackjack.calculate_hand_value(cards)

      # Test aces (soft total)
      cards = [%{rank: "A", suit: "hearts"}, %{rank: "2", suit: "clubs"}]
      assert {13, true} = Blackjack.calculate_hand_value(cards)

      # Test blackjack
      cards = [%{rank: "A", suit: "hearts"}, %{rank: "K", suit: "clubs"}]
      assert {21, true} = Blackjack.calculate_hand_value(cards)
    end

    test "is_blackjack?/1 detects blackjack" do
      blackjack_cards = [%{rank: "A", suit: "hearts"}, %{rank: "K", suit: "clubs"}]
      assert Blackjack.is_blackjack?(blackjack_cards)

      non_blackjack_cards = [%{rank: "10", suit: "hearts"}, %{rank: "K", suit: "clubs"}]
      refute Blackjack.is_blackjack?(non_blackjack_cards)

      three_card_21 = [
        %{rank: "5", suit: "hearts"},
        %{rank: "7", suit: "clubs"},
        %{rank: "9", suit: "diamonds"}
      ]

      refute Blackjack.is_blackjack?(three_card_21)
    end

    test "is_busted?/1 detects busts" do
      busted_cards = [
        %{rank: "10", suit: "hearts"},
        %{rank: "7", suit: "clubs"},
        %{rank: "5", suit: "diamonds"}
      ]

      assert Blackjack.is_busted?(busted_cards)

      safe_cards = [%{rank: "10", suit: "hearts"}, %{rank: "7", suit: "clubs"}]
      refute Blackjack.is_busted?(safe_cards)
    end

    test "deal_initial_cards/2 deals correctly" do
      # Create mock hands
      hands = %{
        1 => %BlackjackHand{hand_cards: [], position: 1},
        2 => %BlackjackHand{hand_cards: [], position: 2}
      }

      deck = [
        %{rank: "A", suit: "hearts"},
        %{rank: "K", suit: "clubs"},
        %{rank: "Q", suit: "diamonds"},
        %{rank: "J", suit: "spades"},
        %{rank: "10", suit: "hearts"}
      ]

      {updated_hands, dealer_cards, remaining_deck} = Blackjack.deal_initial_cards(hands, deck)

      # Each player should have 2 cards
      assert length(Map.get(updated_hands, 1).hand_cards) == 2
      assert length(Map.get(updated_hands, 2).hand_cards) == 2

      # Dealer should have 2 cards
      assert length(dealer_cards) == 2

      # Total cards dealt: 6, so 6 cards remaining from original 11
      assert length(remaining_deck) == 6
    end

    test "determine_outcome/2 calculates correct payouts" do
      # Player blackjack vs dealer non-blackjack
      player_blackjack = [%{rank: "A", suit: "hearts"}, %{rank: "K", suit: "clubs"}]
      dealer_cards = [%{rank: "10", suit: "hearts"}, %{rank: "7", suit: "clubs"}]
      assert {:blackjack, 2.5} = Blackjack.determine_outcome(player_blackjack, dealer_cards)

      # Player wins with higher total
      player_cards = [%{rank: "10", suit: "hearts"}, %{rank: "9", suit: "clubs"}]
      dealer_cards = [%{rank: "10", suit: "hearts"}, %{rank: "7", suit: "clubs"}]
      assert {:win, 2} = Blackjack.determine_outcome(player_cards, dealer_cards)

      # Player loses
      player_cards = [%{rank: "10", suit: "hearts"}, %{rank: "6", suit: "clubs"}]
      dealer_cards = [%{rank: "10", suit: "hearts"}, %{rank: "7", suit: "clubs"}]
      assert {:lose, 0} = Blackjack.determine_outcome(player_cards, dealer_cards)

      # Push (tie)
      player_cards = [%{rank: "10", suit: "hearts"}, %{rank: "7", suit: "clubs"}]
      dealer_cards = [%{rank: "10", suit: "hearts"}, %{rank: "7", suit: "clubs"}]
      assert {:push, 1} = Blackjack.determine_outcome(player_cards, dealer_cards)
    end
  end

  describe "blackjack server" do
    test "create_game/1 creates a new game" do
      assert {:ok, game_id} = Shard.Gambling.BlackjackServer.create_game()
      assert is_binary(game_id)
      assert String.starts_with?(game_id, "blackjack_")
    end

    test "get_game/1 returns game data" do
      {:ok, game_id} = Shard.Gambling.BlackjackServer.create_game()
      assert {:ok, game_data} = Shard.Gambling.BlackjackServer.get_game(game_id)
      assert game_data.game.game_id == game_id
      assert game_data.phase == "waiting"
      assert game_data.hands == []
    end

    test "get_game/1 returns error for non-existent game" do
      assert {:error, :game_not_found} =
               Shard.Gambling.BlackjackServer.get_game("non_existent_game")
    end
  end

  describe "database integration" do
    setup do
      # Create a test user and character
      {:ok, user} =
        Users.register_user(%{
          email: "test#{System.unique_integer()}@example.com",
          password: "password123"
        })

      {:ok, character} =
        Characters.create_character(user.id, %{
          name: "TestCharacter#{System.unique_integer()}",
          class: "warrior"
        })

      %{user: user, character: character}
    end

    test "place_bet/3 places a bet successfully", %{character: character} do
      {:ok, game_id} = Shard.Gambling.BlackjackServer.create_game()

      # Join the game first
      :ok = Shard.Gambling.BlackjackServer.join_game(game_id, character.id, 1)

      # Place a bet
      assert {:ok, hand} = Blackjack.place_bet(game_id, character.id, 100)

      # Verify the bet was placed
      assert hand.bet_amount == 100
      assert hand.status == "playing"

      # Verify gold was deducted
      updated_character = Characters.get_character!(character.id)
      assert updated_character.gold == character.gold - 100
    end

    test "place_bet/3 fails with insufficient gold", %{character: character} do
      {:ok, game_id} = Shard.Gambling.BlackjackServer.create_game()

      # Join the game first
      :ok = Shard.Gambling.BlackjackServer.join_game(game_id, character.id, 1)

      # Try to bet more than available gold
      assert {:error, :insufficient_gold} =
               Blackjack.place_bet(game_id, character.id, character.gold + 1000)
    end

    test "game and hand creation", %{character: character} do
      {:ok, game_id} = Shard.Gambling.BlackjackServer.create_game()

      # Verify game was created in database
      game = Repo.get_by(BlackjackGame, game_id: game_id)
      assert game.game_id == game_id
      assert game.status == "waiting"

      # Join the game
      :ok = Shard.Gambling.BlackjackServer.join_game(game_id, character.id, 1)

      # Verify hand was created
      hand = Repo.get_by(BlackjackHand, blackjack_game_id: game.id, character_id: character.id)
      assert hand.position == 1
      assert hand.bet_amount == 0
      assert hand.status == "betting"
    end
  end
end
