defmodule Shard.Gambling.BetTest do
  use Shard.DataCase

  alias Shard.Gambling.Bet

  describe "changeset/2" do
    @valid_attrs %{
      character_id: 1,
      flip_id: "flip-123",
      amount: 50,
      prediction: "heads",
      result: "pending",
      payout: 0
    }

    test "changeset with valid attributes" do
      changeset = Bet.changeset(%Bet{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset requires character_id, flip_id, amount, and prediction" do
      changeset = Bet.changeset(%Bet{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.character_id
      assert "can't be blank" in errors.flip_id
      assert "can't be blank" in errors.amount
      assert "can't be blank" in errors.prediction
    end

    test "validates amount is greater than 0" do
      invalid_attrs = %{@valid_attrs | amount: 0}
      changeset = Bet.changeset(%Bet{}, invalid_attrs)
      refute changeset.valid?
      assert %{amount: ["must be greater than 0"]} = errors_on(changeset)

      negative_attrs = %{@valid_attrs | amount: -10}
      changeset = Bet.changeset(%Bet{}, negative_attrs)
      refute changeset.valid?
      assert %{amount: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "validates prediction inclusion" do
      invalid_attrs = %{@valid_attrs | prediction: "invalid"}
      changeset = Bet.changeset(%Bet{}, invalid_attrs)
      refute changeset.valid?
      assert %{prediction: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts valid predictions" do
      for prediction <- ["heads", "tails"] do
        attrs = %{@valid_attrs | prediction: prediction}
        changeset = Bet.changeset(%Bet{}, attrs)
        assert changeset.valid?, "Expected #{prediction} to be valid"
      end
    end

    test "validates result inclusion" do
      invalid_attrs = %{@valid_attrs | result: "invalid"}
      changeset = Bet.changeset(%Bet{}, invalid_attrs)
      refute changeset.valid?
      assert %{result: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts valid results" do
      for result <- ["pending", "won", "lost"] do
        attrs = %{@valid_attrs | result: result}
        changeset = Bet.changeset(%Bet{}, attrs)
        assert changeset.valid?, "Expected #{result} to be valid"
      end
    end

    test "accepts default values" do
      minimal_attrs = %{
        character_id: 1,
        flip_id: "flip-123",
        amount: 25,
        prediction: "heads"
      }

      changeset = Bet.changeset(%Bet{}, minimal_attrs)
      assert changeset.valid?
      assert get_field(changeset, :result) == "pending"
      assert get_field(changeset, :payout) == 0
    end

    test "accepts payout values" do
      attrs = %{@valid_attrs | result: "won", payout: 100}
      changeset = Bet.changeset(%Bet{}, attrs)
      assert changeset.valid?
      assert get_field(changeset, :payout) == 100
    end
  end
end
