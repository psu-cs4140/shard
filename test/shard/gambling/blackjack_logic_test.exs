defmodule Shard.Gambling.BlackjackLogicTest do
  use ExUnit.Case
  alias Shard.Gambling.Blackjack

  describe "calculate_hand_value/1" do
    test "number cards sum correctly" do
      cards = [%{rank: "2"}, %{rank: "3"}, %{rank: "4"}]
      assert {9, false} = Blackjack.calculate_hand_value(cards)
    end

    test "face cards count as 10" do
      cards = [%{rank: "J"}, %{rank: "Q"}, %{rank: "K"}]
      assert {30, false} = Blackjack.calculate_hand_value(cards)
    end

    test "ace counts as 11 (soft)" do
      cards = [%{rank: "A"}, %{rank: "5"}]
      assert {16, true} = Blackjack.calculate_hand_value(cards)
    end

    test "ace counts as 1 (hard) if > 21" do
      cards = [%{rank: "A"}, %{rank: "5"}, %{rank: "10"}]
      assert {16, false} = Blackjack.calculate_hand_value(cards)
    end

    test "multiple aces handled correctly" do
      # A + A = 2 or 12. Soft 12.
      cards = [%{rank: "A"}, %{rank: "A"}]
      assert {12, true} = Blackjack.calculate_hand_value(cards)

      # A + A + A = 3 or 13. Soft 13.
      cards = [%{rank: "A"}, %{rank: "A"}, %{rank: "A"}]
      assert {13, true} = Blackjack.calculate_hand_value(cards)

      # A + A + 10 = 12. Hard.
      cards = [%{rank: "A"}, %{rank: "A"}, %{rank: "10"}]
      assert {12, false} = Blackjack.calculate_hand_value(cards)
    end
  end

  describe "determine_outcome/2" do
    test "player bust is always a loss" do
      # 22
      player = [%{rank: "10"}, %{rank: "10"}, %{rank: "2"}]
      # 17
      dealer = [%{rank: "10"}, %{rank: "7"}]
      assert {:lost, 0} = Blackjack.determine_outcome(player, dealer)

      # Even if dealer busts too
      # 25
      dealer_bust = [%{rank: "10"}, %{rank: "10"}, %{rank: "5"}]
      assert {:lost, 0} = Blackjack.determine_outcome(player, dealer_bust)
    end

    test "dealer bust is a win (if player not busted)" do
      # 20
      player = [%{rank: "10"}, %{rank: "10"}]
      # 25
      dealer = [%{rank: "10"}, %{rank: "5"}, %{rank: "10"}]
      assert {:won, 2} = Blackjack.determine_outcome(player, dealer)
    end

    test "higher score wins" do
      # 20
      player = [%{rank: "10"}, %{rank: "10"}]
      # 19
      dealer = [%{rank: "10"}, %{rank: "9"}]
      assert {:won, 2} = Blackjack.determine_outcome(player, dealer)
    end

    test "lower score loses" do
      # 19
      player = [%{rank: "10"}, %{rank: "9"}]
      # 20
      dealer = [%{rank: "10"}, %{rank: "10"}]
      assert {:lost, 0} = Blackjack.determine_outcome(player, dealer)
    end

    test "push on equal score" do
      # 20
      player = [%{rank: "10"}, %{rank: "10"}]
      # 20
      dealer = [%{rank: "10"}, %{rank: "J"}]
      assert {:push, 1} = Blackjack.determine_outcome(player, dealer)
    end

    test "blackjack wins 3:2" do
      # BJ
      player = [%{rank: "A"}, %{rank: "K"}]
      # 20
      dealer = [%{rank: "10"}, %{rank: "J"}]
      assert {:blackjack_win, 2.5} = Blackjack.determine_outcome(player, dealer)
    end

    test "dealer blackjack beats player 21 (non-BJ)" do
      # 21
      player = [%{rank: "10"}, %{rank: "5"}, %{rank: "6"}]
      # BJ
      dealer = [%{rank: "A"}, %{rank: "K"}]
      assert {:lost, 0} = Blackjack.determine_outcome(player, dealer)
    end

    test "blackjack push" do
      # BJ
      player = [%{rank: "A"}, %{rank: "K"}]
      # BJ
      dealer = [%{rank: "A"}, %{rank: "K"}]
      # Logic says dealer_blackjack && !player_blackjack -> lose.
      # player_blackjack && !dealer_blackjack -> win.
      # Both -> fallthrough to true (Push).
      assert {:push, 1} = Blackjack.determine_outcome(player, dealer)
    end
  end
end
