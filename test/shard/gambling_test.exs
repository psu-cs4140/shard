defmodule Shard.GamblingTest do
  use Shard.DataCase

  alias Shard.Gambling
  alias Shard.Gambling.{BlackjackGame, BlackjackHand}
  import Shard.UsersFixtures

  describe "blackjack games" do
    @invalid_attrs %{character_id: nil, bet_amount: nil}

    test "create_blackjack_game/1 with valid data creates a game" do
      character = character_fixture()
      
      attrs = %{
        character_id: character.id,
        bet_amount: 100,
        status: "active"
      }

      assert {:ok, %BlackjackGame{} = game} = Gambling.create_blackjack_game(attrs)
      assert game.character_id == character.id
      assert game.bet_amount == 100
      assert game.status == "active"
    end

    test "create_blackjack_game/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Gambling.create_blackjack_game(@invalid_attrs)
    end

    test "list_blackjack_games/0 returns all games" do
      character = character_fixture()
      {:ok, game} = Gambling.create_blackjack_game(%{
        character_id: character.id,
        bet_amount: 100,
        status: "active"
      })
      
      games = Gambling.list_blackjack_games()
      assert length(games) >= 1
      assert Enum.any?(games, fn g -> g.id == game.id end)
    end

    test "get_blackjack_game!/1 returns the game with given id" do
      character = character_fixture()
      {:ok, game} = Gambling.create_blackjack_game(%{
        character_id: character.id,
        bet_amount: 100,
        status: "active"
      })

      assert Gambling.get_blackjack_game!(game.id).id == game.id
    end

    test "update_blackjack_game/2 with valid data updates the game" do
      character = character_fixture()
      {:ok, game} = Gambling.create_blackjack_game(%{
        character_id: character.id,
        bet_amount: 100,
        status: "active"
      })

      update_attrs = %{status: "completed", bet_amount: 200}

      assert {:ok, %BlackjackGame{} = game} = Gambling.update_blackjack_game(game, update_attrs)
      assert game.status == "completed"
      assert game.bet_amount == 200
    end

    test "update_blackjack_game/2 with invalid data returns error changeset" do
      character = character_fixture()
      {:ok, game} = Gambling.create_blackjack_game(%{
        character_id: character.id,
        bet_amount: 100,
        status: "active"
      })

      assert {:error, %Ecto.Changeset{}} = Gambling.update_blackjack_game(game, @invalid_attrs)
      assert game == Gambling.get_blackjack_game!(game.id)
    end

    test "delete_blackjack_game/1 deletes the game" do
      character = character_fixture()
      {:ok, game} = Gambling.create_blackjack_game(%{
        character_id: character.id,
        bet_amount: 100,
        status: "active"
      })

      assert {:ok, %BlackjackGame{}} = Gambling.delete_blackjack_game(game)
      assert_raise Ecto.NoResultsError, fn -> Gambling.get_blackjack_game!(game.id) end
    end

    test "change_blackjack_game/1 returns a game changeset" do
      character = character_fixture()
      {:ok, game} = Gambling.create_blackjack_game(%{
        character_id: character.id,
        bet_amount: 100,
        status: "active"
      })

      assert %Ecto.Changeset{} = Gambling.change_blackjack_game(game)
    end
  end

  describe "blackjack hands" do
    setup do
      character = character_fixture()
      {:ok, game} = Gambling.create_blackjack_game(%{
        character_id: character.id,
        bet_amount: 100,
        status: "active"
      })
      
      %{character: character, game: game}
    end

    test "create_blackjack_hand/1 with valid data creates a hand", %{character: character, game: game} do
      attrs = %{
        blackjack_game_id: game.id,
        character_id: character.id,
        position: 1,
        hand_cards: [],
        bet_amount: 100,
        status: "active"
      }

      assert {:ok, %BlackjackHand{} = hand} = Gambling.create_blackjack_hand(attrs)
      assert hand.blackjack_game_id == game.id
      assert hand.character_id == character.id
      assert hand.position == 1
      assert hand.bet_amount == 100
      assert hand.status == "active"
    end

    test "create_blackjack_hand/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Gambling.create_blackjack_hand(%{})
    end

    test "list_game_hands/1 returns hands for a game", %{character: character, game: game} do
      {:ok, hand} = Gambling.create_blackjack_hand(%{
        blackjack_game_id: game.id,
        character_id: character.id,
        position: 1,
        hand_cards: [],
        bet_amount: 100,
        status: "active"
      })

      hands = Gambling.list_game_hands(game.id)
      assert length(hands) >= 1
      assert Enum.any?(hands, fn h -> h.id == hand.id end)
    end

    test "get_blackjack_hand!/1 returns the hand with given id", %{character: character, game: game} do
      {:ok, hand} = Gambling.create_blackjack_hand(%{
        blackjack_game_id: game.id,
        character_id: character.id,
        position: 1,
        hand_cards: [],
        bet_amount: 100,
        status: "active"
      })

      assert Gambling.get_blackjack_hand!(hand.id).id == hand.id
    end

    test "update_blackjack_hand/2 with valid data updates the hand", %{character: character, game: game} do
      {:ok, hand} = Gambling.create_blackjack_hand(%{
        blackjack_game_id: game.id,
        character_id: character.id,
        position: 1,
        hand_cards: [],
        bet_amount: 100,
        status: "active"
      })

      update_attrs = %{
        status: "completed",
        outcome: "win",
        hand_cards: [%{"suit" => "hearts", "rank" => "ace"}]
      }

      assert {:ok, %BlackjackHand{} = hand} = Gambling.update_blackjack_hand(hand, update_attrs)
      assert hand.status == "completed"
      assert hand.outcome == "win"
      assert length(hand.hand_cards) == 1
    end

    test "delete_blackjack_hand/1 deletes the hand", %{character: character, game: game} do
      {:ok, hand} = Gambling.create_blackjack_hand(%{
        blackjack_game_id: game.id,
        character_id: character.id,
        position: 1,
        hand_cards: [],
        bet_amount: 100,
        status: "active"
      })

      assert {:ok, %BlackjackHand{}} = Gambling.delete_blackjack_hand(hand)
      assert_raise Ecto.NoResultsError, fn -> Gambling.get_blackjack_hand!(hand.id) end
    end
  end

  describe "game logic" do
    test "calculate_hand_value/1 calculates correct values" do
      # Test number cards
      hand1 = [
        %{"suit" => "hearts", "rank" => "5"},
        %{"suit" => "spades", "rank" => "7"}
      ]
      assert Gambling.calculate_hand_value(hand1) == 12

      # Test face cards
      hand2 = [
        %{"suit" => "hearts", "rank" => "king"},
        %{"suit" => "spades", "rank" => "queen"}
      ]
      assert Gambling.calculate_hand_value(hand2) == 20

      # Test ace as 11
      hand3 = [
        %{"suit" => "hearts", "rank" => "ace"},
        %{"suit" => "spades", "rank" => "9"}
      ]
      assert Gambling.calculate_hand_value(hand3) == 20

      # Test ace as 1 (soft ace)
      hand4 = [
        %{"suit" => "hearts", "rank" => "ace"},
        %{"suit" => "spades", "rank" => "king"},
        %{"suit" => "clubs", "rank" => "5"}
      ]
      assert Gambling.calculate_hand_value(hand4) == 16
    end

    test "is_blackjack?/1 identifies natural blackjack" do
      blackjack_hand = [
        %{"suit" => "hearts", "rank" => "ace"},
        %{"suit" => "spades", "rank" => "king"}
      ]
      assert Gambling.is_blackjack?(blackjack_hand) == true

      regular_hand = [
        %{"suit" => "hearts", "rank" => "10"},
        %{"suit" => "spades", "rank" => "9"}
      ]
      assert Gambling.is_blackjack?(regular_hand) == false

      three_card_21 = [
        %{"suit" => "hearts", "rank" => "7"},
        %{"suit" => "spades", "rank" => "7"},
        %{"suit" => "clubs", "rank" => "7"}
      ]
      assert Gambling.is_blackjack?(three_card_21) == false
    end

    test "is_bust?/1 identifies busted hands" do
      bust_hand = [
        %{"suit" => "hearts", "rank" => "king"},
        %{"suit" => "spades", "rank" => "queen"},
        %{"suit" => "clubs", "rank" => "5"}
      ]
      assert Gambling.is_bust?(bust_hand) == true

      safe_hand = [
        %{"suit" => "hearts", "rank" => "10"},
        %{"suit" => "spades", "rank" => "9"}
      ]
      assert Gambling.is_bust?(safe_hand) == false
    end

    test "deal_card/0 returns a valid card" do
      card = Gambling.deal_card()
      assert is_map(card)
      assert Map.has_key?(card, "suit")
      assert Map.has_key?(card, "rank")
      assert card["suit"] in ["hearts", "diamonds", "clubs", "spades"]
      assert card["rank"] in ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"]
    end

    test "shuffle_deck/0 returns a shuffled deck" do
      deck = Gambling.shuffle_deck()
      assert is_list(deck)
      assert length(deck) == 52
      
      # Check that all cards are present
      suits = ["hearts", "diamonds", "clubs", "spades"]
      ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"]
      
      for suit <- suits, rank <- ranks do
        assert Enum.any?(deck, fn card -> card["suit"] == suit and card["rank"] == rank end)
      end
    end
  end

  describe "BlackjackGame changeset" do
    test "validates required fields" do
      changeset = BlackjackGame.changeset(%BlackjackGame{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.character_id
      assert "can't be blank" in errors.bet_amount
    end

    test "validates positive bet amount" do
      attrs = %{
        character_id: 1,
        bet_amount: -100,
        status: "active"
      }

      changeset = BlackjackGame.changeset(%BlackjackGame{}, attrs)
      refute changeset.valid?
      assert %{bet_amount: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "validates status inclusion" do
      attrs = %{
        character_id: 1,
        bet_amount: 100,
        status: "invalid_status"
      }

      changeset = BlackjackGame.changeset(%BlackjackGame{}, attrs)
      refute changeset.valid?
      assert %{status: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts valid game data" do
      attrs = %{
        character_id: 1,
        bet_amount: 100,
        status: "active"
      }

      changeset = BlackjackGame.changeset(%BlackjackGame{}, attrs)
      assert changeset.valid?
    end
  end

  describe "BlackjackHand changeset" do
    test "validates required fields" do
      changeset = BlackjackHand.changeset(%BlackjackHand{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.blackjack_game_id
      assert "can't be blank" in errors.character_id
      assert "can't be blank" in errors.position
      assert "can't be blank" in errors.bet_amount
    end

    test "validates positive position" do
      attrs = %{
        blackjack_game_id: 1,
        character_id: 1,
        position: 0,
        bet_amount: 100,
        status: "active"
      }

      changeset = BlackjackHand.changeset(%BlackjackHand{}, attrs)
      refute changeset.valid?
      assert %{position: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "validates positive bet amount" do
      attrs = %{
        blackjack_game_id: 1,
        character_id: 1,
        position: 1,
        bet_amount: -100,
        status: "active"
      }

      changeset = BlackjackHand.changeset(%BlackjackHand{}, attrs)
      refute changeset.valid?
      assert %{bet_amount: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "accepts valid hand data" do
      attrs = %{
        blackjack_game_id: 1,
        character_id: 1,
        position: 1,
        hand_cards: [],
        bet_amount: 100,
        status: "active"
      }

      changeset = BlackjackHand.changeset(%BlackjackHand{}, attrs)
      assert changeset.valid?
    end
  end

  # Helper function to create a test character
  defp character_fixture(attrs \\ %{}) do
    user = user_fixture()

    valid_attrs =
      Enum.into(attrs, %{
        name: "Test Character #{System.unique_integer([:positive])}",
        class: "warrior",
        race: "human",
        user_id: user.id
      })

    {:ok, character} = Shard.Characters.create_character(valid_attrs)
    character
  end

  defp create_user_fixture do
    unique_email = "user#{System.unique_integer([:positive])}@example.com"

    {:ok, user} =
      Shard.Users.register_user(%{
        email: unique_email,
        password: "password123password123"
      })

    user
  end
end
