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
        %{rank: "10", suit: "hearts"},
        %{rank: "9", suit: "clubs"},
        %{rank: "8", suit: "diamonds"},
        %{rank: "7", suit: "spades"},
        %{rank: "6", suit: "hearts"},
        %{rank: "5", suit: "clubs"},
        %{rank: "4", suit: "diamonds"}
      ]

      {updated_hands, dealer_cards, remaining_deck} = Blackjack.deal_initial_cards(hands, deck)

      # Each player should have 2 cards
      assert length(Map.get(updated_hands, 1).hand_cards) == 2
      assert length(Map.get(updated_hands, 2).hand_cards) == 2

      # Dealer should have 2 cards
      assert length(dealer_cards) == 2

      # Total cards dealt: 6, so 5 cards remaining from original 11
      assert length(remaining_deck) == 5
    end

    test "determine_outcome/2 calculates correct payouts" do
      # Player blackjack vs dealer non-blackjack
      player_blackjack = [%{rank: "A", suit: "hearts"}, %{rank: "K", suit: "clubs"}]
      dealer_cards = [%{rank: "10", suit: "hearts"}, %{rank: "7", suit: "clubs"}]
      assert {:blackjack_win, 2.5} = Blackjack.determine_outcome(player_blackjack, dealer_cards)

      # Player wins with higher total
      player_cards = [%{rank: "10", suit: "hearts"}, %{rank: "9", suit: "clubs"}]
      dealer_cards = [%{rank: "10", suit: "hearts"}, %{rank: "7", suit: "clubs"}]
      assert {:won, 2} = Blackjack.determine_outcome(player_cards, dealer_cards)

      # Player loses
      player_cards = [%{rank: "10", suit: "hearts"}, %{rank: "6", suit: "clubs"}]
      dealer_cards = [%{rank: "10", suit: "hearts"}, %{rank: "7", suit: "clubs"}]
      assert {:lost, 0} = Blackjack.determine_outcome(player_cards, dealer_cards)

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
      assert game_data.phase == :waiting
      assert game_data.hands == []
    end

    test "get_game/1 returns error for non-existent game" do
      assert {:error, :game_not_found} =
               Shard.Gambling.BlackjackServer.get_game("non_existent_game")
    end

    test "get_or_create_game/0 creates new game when only finished ones exist" do
      # Create a game and finish it manually (update status)
      {:ok, game_id} = Shard.Gambling.BlackjackServer.create_game()
      Shard.Gambling.Blackjack.update_game_status(game_id, "finished")

      # Should create a NEW game, not crash
      assert {:ok, new_game_id} = Shard.Gambling.BlackjackServer.get_or_create_game()
      assert new_game_id != game_id
      assert String.starts_with?(new_game_id, "blackjack_")
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
        Characters.create_character(%{
          name: "TestCharacter#{System.unique_integer()}",
          class: "warrior",
          race: "human",
          gold: 1000,
          user_id: user.id
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
    test "join_game/3 allows joining during betting phase with correct status", %{character: character} do
      {:ok, game_id} = Shard.Gambling.BlackjackServer.create_game()

      # First player joins, starts betting phase
      {:ok, char1} = Characters.create_character(%{name: "P1", class: "warrior", race: "human", user_id: character.user_id})
      :ok = Shard.Gambling.BlackjackServer.join_game(game_id, char1.id, 1)

      {:ok, game_data} = Shard.Gambling.BlackjackServer.get_game(game_id)
      assert game_data.phase == :betting

      # Second player joins during betting phase
      :ok = Shard.Gambling.BlackjackServer.join_game(game_id, character.id, 2)

      # Check status
      {:ok, game_data} = Shard.Gambling.BlackjackServer.get_game(game_id)
      hand = Enum.find(game_data.hands, &(&1.character_id == character.id))
      assert hand.status == "betting"
    end

    test "game restarts automatically after reset", %{character: character} do
      {:ok, game_id} = Shard.Gambling.BlackjackServer.create_game()
      
      # Join game
      :ok = Shard.Gambling.BlackjackServer.join_game(game_id, character.id, 1)
      
      # Simulate game finished state manually
      Shard.Gambling.Blackjack.update_game_status(game_id, "finished")
      
      # Trigger reset directly (usually called by timer)
      send(Process.whereis(Shard.Gambling.BlackjackServer), {:reset_game, game_id})
      
      # Allow time for processing
      Process.sleep(100)
      
      # Verify game is back in betting phase
      {:ok, game_data} = Shard.Gambling.BlackjackServer.get_game(game_id)
      assert game_data.phase == :betting
      
      # Verify player hand is reset
      hand = Enum.find(game_data.hands, &(&1.character_id == character.id))
      assert hand.status == "betting"
      assert hand.bet_amount == 0
      assert hand.hand_cards == []
    end

    test "sequential dealing deals cards over time", %{character: character} do
      {:ok, game_id} = Shard.Gambling.BlackjackServer.create_game()
      
      # Join and bet
      :ok = Shard.Gambling.BlackjackServer.join_game(game_id, character.id, 1)
      :ok = Shard.Gambling.BlackjackServer.place_bet(game_id, character.id, 100)
      
      # Force start dealing phase (simulating timeout)
      state = :sys.get_state(Process.whereis(Shard.Gambling.BlackjackServer))
      send(Process.whereis(Shard.Gambling.BlackjackServer), {:phase_timeout, game_id})
      
      # Initially, phase should be dealing but no cards yet (or just started)
      Process.sleep(100)
      {:ok, game_data} = Shard.Gambling.BlackjackServer.get_game(game_id)
      assert game_data.phase == :dealing
      
      # Wait for dealing loop (approx 4 cards * 800ms + initial 500ms = ~3.7s)
      # Let's wait a bit and check partial progress
      Process.sleep(1000)
      {:ok, game_data} = Shard.Gambling.BlackjackServer.get_game(game_id)
      hand = Enum.find(game_data.hands, &(&1.character_id == character.id))
      # Should have at least 1 card
      assert length(hand.hand_cards) >= 1
      
      # Wait for completion
      Process.sleep(4000)
      {:ok, game_data} = Shard.Gambling.BlackjackServer.get_game(game_id)
      assert game_data.phase == :playing
      
      hand = Enum.find(game_data.hands, &(&1.character_id == character.id))
      assert length(hand.hand_cards) == 2
      assert length(game_data.game.dealer_hand) == 2
    end
  end
end
