defmodule Shard.Gambling.BlackjackServerTest do
  use Shard.DataCase, async: false
  alias Shard.Gambling.BlackjackServer
  alias Shard.Repo

  setup do
    # Create test users and characters
    user1 = Shard.UsersFixtures.user_fixture()

    char1 =
      Shard.CharactersFixtures.character_fixture(%{
        user: user1,
        gold: 1000,
        name: "TestChar#{System.unique_integer()}"
      })

    user2 = Shard.UsersFixtures.user_fixture()

    char2 =
      Shard.CharactersFixtures.character_fixture(%{
        user: user2,
        gold: 1000,
        name: "TestChar#{System.unique_integer()}"
      })

    # Restart BlackjackServer to ensure clean state for each test
    if pid = Process.whereis(BlackjackServer) do
      Process.exit(pid, :kill)
      # Allow supervisor to restart it
      Process.sleep(50)
    end

    # Allow BlackjackServer to use shared db connection
    pid = Process.whereis(BlackjackServer)
    Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), pid)

    {:ok, char1: char1, char2: char2}
  end

  defp wait_for_phase(game_id, target_phase, attempts \\ 50) do
    {:ok, game_data} = BlackjackServer.get_game(game_id)

    if game_data.phase == target_phase do
      game_data
    else
      if attempts > 0 do
        Process.sleep(100)
        wait_for_phase(game_id, target_phase, attempts - 1)
      else
        flunk("Timeout waiting for phase #{target_phase}, current: #{game_data.phase}")
      end
    end
  end

  describe "game lifecycle" do
    test "create and get game", %{char1: _char1} do
      {:ok, game_id} = BlackjackServer.get_or_create_game()
      assert is_binary(game_id)

      {:ok, game_data} = BlackjackServer.get_game(game_id)
      assert game_data.game.game_id == game_id
      assert game_data.phase in [:waiting, :betting]
    end

    test "join game and place bet", %{char1: char1} do
      {:ok, game_id} = BlackjackServer.get_or_create_game()

      # Join
      assert :ok = BlackjackServer.join_game(game_id, char1.id, 1)

      # Verify joined
      {:ok, game_data} = BlackjackServer.get_game(game_id)
      hand = Enum.find(game_data.hands, fn h -> h.character_id == char1.id end)
      assert hand
      assert hand.position == 1

      # Wait for betting phase (if not already)
      wait_for_phase(game_id, :betting)

      # Place bet
      assert :ok = BlackjackServer.place_bet(game_id, char1.id, 50)

      # Verify bet
      {:ok, final_data} = BlackjackServer.get_game(game_id)
      hand = Enum.find(final_data.hands, fn h -> h.character_id == char1.id end)
      assert hand.bet_amount == 50
    end
  end

  describe "game flow" do
    test "dealing phase and player turns", %{char1: char1} do
      # Create private game to avoid others
      {:ok, game_id} = BlackjackServer.create_game(1)

      # Join and bet
      BlackjackServer.join_game(game_id, char1.id, 1)
      BlackjackServer.place_bet(game_id, char1.id, 100)

      # Trigger timeout manually
      state = :sys.get_state(BlackjackServer)
      game_state = Map.get(state.games, game_id)
      phase_ref = game_state.phase_ref
      send(BlackjackServer, {:phase_timeout, game_id, phase_ref})

      # Wait for dealing to finish and enter playing phase
      game_data = wait_for_phase(game_id, :playing)

      assert game_data.current_player_id == char1.id

      # Player Hit
      assert :ok = BlackjackServer.hit(game_id, char1.id)

      {:ok, game_data} = BlackjackServer.get_game(game_id)
      hand = Enum.find(game_data.hands, fn h -> h.character_id == char1.id end)
      # 2 initial + 1 hit
      assert length(hand.hand_cards) >= 3

      # Player Stand
      assert :ok = BlackjackServer.stand(game_id, char1.id)

      # Should trigger dealer turn and finish. Wait for finished/waiting/betting
      # We can't use generic wrapper easily since result could be any of these.
      Process.sleep(1000)
      {:ok, final_data} = BlackjackServer.get_game(game_id)
      assert final_data.phase in [:finished, :waiting, :betting]
    end

    test "player leaves game", %{char1: char1} do
      {:ok, game_id} = BlackjackServer.create_game(1)
      BlackjackServer.join_game(game_id, char1.id, 1)

      assert :ok = BlackjackServer.leave_game(game_id, char1.id)

      {:ok, game_data} = BlackjackServer.get_game(game_id)
      refute Enum.any?(game_data.hands, fn h -> h.character_id == char1.id end)
    end

    test "join late waits for next round", %{char1: char1, char2: char2} do
      {:ok, game_id} = BlackjackServer.create_game(2)

      # Char1 starts game
      BlackjackServer.join_game(game_id, char1.id, 1)
      BlackjackServer.place_bet(game_id, char1.id, 10)

      # Force deal (timeout)
      sys_state = :sys.get_state(BlackjackServer)
      game_state = Map.get(sys_state.games, game_id)
      send(BlackjackServer, {:phase_timeout, game_id, game_state.phase_ref})

      # Wait for playing
      wait_for_phase(game_id, :playing)

      # Char2 joins now
      assert :ok = BlackjackServer.join_game(game_id, char2.id, 2)

      {:ok, final_data} = BlackjackServer.get_game(game_id)
      hand2 = Enum.find(final_data.hands, fn h -> h.character_id == char2.id end)
      assert hand2.status == "waiting"
    end

    test "double down not implemented but hit works", %{char1: char1} do
      # Just verifying normal hit
      {:ok, game_id} = BlackjackServer.create_game(1)
      BlackjackServer.join_game(game_id, char1.id, 1)
      BlackjackServer.place_bet(game_id, char1.id, 100)

      send(
        BlackjackServer,
        {:phase_timeout, game_id,
         Map.get(:sys.get_state(BlackjackServer).games, game_id).phase_ref}
      )

      # Wait for playing
      wait_for_phase(game_id, :playing)

      assert :ok = BlackjackServer.hit(game_id, char1.id)
    end
  end
end
