defmodule Shard.PayoutTest do
  use Shard.DataCase
  alias Shard.Gambling.Blackjack
  alias Shard.Characters.Character
  alias Shard.Gambling.BlackjackServer

  setup do
    user = Shard.Repo.insert!(%Shard.Users.User{email: "test@example.com", hashed_password: "password"})
    character = Shard.Repo.insert!(%Character{
      user_id: user.id,
      name: "Gambler",
      gold: 1000,
      level: 1,
      class: "Warrior",
      race: "Human"
    })
    %{character: character}
  end

  test "process_payouts handles wins correctly", %{character: character} do
    # 1. Start Game
    {:ok, game_id} = BlackjackServer.create_game()
    game_pid = Process.whereis(BlackjackServer)

    # 2. Join and Bet
    # Wait for betting phase/game setup if needed. join_game usually works anytime if phase is betting/waiting.
    # Assuming waiting phase initially.
    BlackjackServer.join_game(game_id, character.id, 1)
    
    # Force phase to betting to be sure
    :sys.replace_state(game_pid, fn state ->
      game_state = Map.get(state.games, game_id)
      %{state | games: Map.put(state.games, game_id, %{game_state | phase: :betting})}
    end)

    BlackjackServer.place_bet(game_id, character.id, 100)

    # Verify deduction
    character = Repo.get(Character, character.id)
    assert character.gold == 900

    # 3. Deal (Sequential dealing might take time, we can manually insert hands)
    # We will manually setup the DB state to simulate a played round before payout.
    # Actually process_payouts reads from DB. So we just need DB state correct.
    
    # Get the hand ID
    hand = Blackjack.get_hand(game_id, character.id)
    
    # Update Hand to Winning State (20 vs 18)
    player_cards = [%{rank: "K", suit: "hearts"}, %{rank: "Q", suit: "hearts"}] # 20
    Repo.update!(Ecto.Changeset.change(hand, %{hand_cards: player_cards, status: "playing"}))

    dealer_cards = [%{rank: "10", suit: "spades"}, %{rank: "8", suit: "clubs"}] # 18
    # NOTE: process_payouts takes dealer_cards as argument.

    # 4. Process Payouts
    Blackjack.process_payouts(game_id, dealer_cards)

    # 5. Verify Gold
    character = Repo.get(Character, character.id)
    # Win = 2x bet returned (200). Balance 900 + 200 = 1100.
    assert character.gold == 1100
    
    # Verify Hand Outcome
    hand = Repo.get(Shard.Gambling.BlackjackHand, hand.id)
    assert hand.outcome == "won"
    assert hand.payout == 200
  end

  test "process_payouts handles pushes correctly", %{character: character} do
    {:ok, game_id} = BlackjackServer.create_game()
    game_pid = Process.whereis(BlackjackServer)
    
    BlackjackServer.join_game(game_id, character.id, 1)
    
    :sys.replace_state(game_pid, fn state ->
      game_state = Map.get(state.games, game_id)
      %{state | games: Map.put(state.games, game_id, %{game_state | phase: :betting})}
    end)
    
    BlackjackServer.place_bet(game_id, character.id, 100)
    
    # 20 vs 20
    hand = Blackjack.get_hand(game_id, character.id)
    player_cards = [%{rank: "K", suit: "hearts"}, %{rank: "Q", suit: "hearts"}] # 20
    Repo.update!(Ecto.Changeset.change(hand, %{hand_cards: player_cards, status: "playing"}))
    
    dealer_cards = [%{rank: "10", suit: "spades"}, %{rank: "Q", suit: "clubs"}] # 20
    
    Blackjack.process_payouts(game_id, dealer_cards)
    
    character = Repo.get(Character, character.id)
    # Push = 1x bet returned (100). Balance 900 + 100 = 1000.
    assert character.gold == 1000
    
    hand = Repo.get(Shard.Gambling.BlackjackHand, hand.id)
    assert hand.outcome == "push"
    assert hand.payout == 100
  end
end
