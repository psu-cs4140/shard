defmodule Shard.Rewards do
  @moduledoc """
  The Rewards context - handles daily login rewards and other reward systems.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo
  alias Shard.Rewards.DailyLoginReward
  alias Shard.Users.User

  @doc """
  Gets the daily login reward record for a user.
  """
  def get_daily_login_reward(user_id) do
    Repo.get_by(DailyLoginReward, user_id: user_id)
  end

  @doc """
  Checks if a user can claim their daily reward.
  Returns {:ok, :can_claim} if they can claim today,
  {:ok, :already_claimed} if they already claimed today,
  or {:error, reason} if there's an issue.
  """
  def can_claim_daily_reward?(user_id) do
    today = Date.utc_today()
    
    case get_daily_login_reward(user_id) do
      nil -> {:ok, :can_claim}
      %DailyLoginReward{last_claim_date: last_claim} ->
        case Date.compare(today, last_claim) do
          :gt -> {:ok, :can_claim}
          :eq -> {:ok, :already_claimed}
          :lt -> {:error, :future_date}
        end
    end
  end

  @doc """
  Claims the daily login reward for a user.
  Returns {:ok, reward_info} with details about what was received,
  or {:error, reason} if the reward cannot be claimed.
  """
  def claim_daily_reward(user_id) do
    case can_claim_daily_reward?(user_id) do
      {:ok, :can_claim} ->
        Repo.transact(fn ->
          today = Date.utc_today()
          
          case get_daily_login_reward(user_id) do
            nil ->
              # First time claiming
              create_daily_reward_record(user_id, today, 1)
              
            existing_record ->
              # Update existing record
              yesterday = Date.add(today, -1)
              new_streak = if Date.compare(existing_record.last_claim_date, yesterday) == :eq do
                existing_record.streak_count + 1
              else
                1  # Reset streak if more than a day has passed
              end
              
              update_daily_reward_record(existing_record, today, new_streak)
          end
          
          # Calculate rewards
          calculate_and_give_rewards(user_id)
        end)
        
      {:ok, :already_claimed} ->
        {:error, :already_claimed_today}
        
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Gets the current streak for a user.
  """
  def get_current_streak(user_id) do
    case get_daily_login_reward(user_id) do
      nil -> 0
      %DailyLoginReward{streak_count: streak, last_claim_date: last_claim} ->
        today = Date.utc_today()
        yesterday = Date.add(today, -1)
        
        cond do
          Date.compare(last_claim, today) == :eq -> streak
          Date.compare(last_claim, yesterday) == :eq -> streak
          true -> 0  # Streak broken
        end
    end
  end

  defp create_daily_reward_record(user_id, date, streak) do
    %DailyLoginReward{}
    |> DailyLoginReward.changeset(%{
      user_id: user_id,
      last_claim_date: date,
      streak_count: streak,
      total_claims: 1
    })
    |> Repo.insert!()
  end

  defp update_daily_reward_record(record, date, new_streak) do
    record
    |> DailyLoginReward.changeset(%{
      last_claim_date: date,
      streak_count: new_streak,
      total_claims: record.total_claims + 1
    })
    |> Repo.update!()
  end

  defp calculate_and_give_rewards(user_id) do
    # Base gold reward (could be adjusted based on streak)
    base_gold = 100
    streak = get_current_streak(user_id)
    
    # Bonus gold for streak (10 gold per day in streak, max 500 bonus)
    streak_bonus = min(streak * 10, 500)
    total_gold = base_gold + streak_bonus
    
    # 50% chance for lootbox
    gets_lootbox = :rand.uniform() < 0.5
    
    # Give the rewards (you'll need to implement these functions based on your existing systems)
    give_gold_to_user(user_id, total_gold)
    
    lootbox_item = if gets_lootbox do
      give_lootbox_to_user(user_id)
    else
      nil
    end
    
    {:ok, %{
      gold: total_gold,
      lootbox: lootbox_item,
      streak: streak,
      streak_bonus: streak_bonus
    }}
  end

  # These functions need to be implemented based on your existing systems
  defp give_gold_to_user(user_id, amount) do
    # TODO: Implement gold giving logic
    # This should integrate with your existing character/currency system
    IO.puts("Giving #{amount} gold to user #{user_id}")
  end

  defp give_lootbox_to_user(user_id) do
    # TODO: Implement lootbox giving logic
    # This should integrate with your existing inventory system
    IO.puts("Giving lootbox to user #{user_id}")
    "Basic Lootbox"  # Return the item name/type
  end
end
