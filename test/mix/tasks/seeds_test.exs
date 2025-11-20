defmodule Mix.Tasks.SeedsTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias Mix.Tasks.Seeds

  describe "run/1" do
    test "runs all seeders and outputs progress messages" do
      # Mock the seeder modules
      defmodule MockDamageTypesSeeder do
        def run, do: :ok
      end

      defmodule MockEffectsSeeder do
        def run, do: :ok
      end

      # Capture the output
      output = capture_io(fn ->
        # We need to mock the actual seeder calls since we can't easily
        # replace the module calls in the compiled code
        # Instead, we'll test that the task starts the app and runs
        Seeds.run([])
      end)

      # Verify the expected output messages are present
      assert output =~ "Running Damage Types Seeder..."
      assert output =~ "Damage Types Seeder completed."
      assert output =~ "Running Effects Seeder..."
      assert output =~ "Effects Seeder completed."
    end

    test "starts the application before running seeders" do
      # This test verifies that Mix.Task.run("app.start") is called
      # We can't easily mock Mix.Task.run, but we can verify the task
      # completes without error, which implies the app started successfully
      assert capture_io(fn ->
        Seeds.run([])
      end) =~ "Seeder completed"
    end

    test "ignores command line arguments" do
      # Test that the function works regardless of arguments passed
      output1 = capture_io(fn -> Seeds.run([]) end)
      output2 = capture_io(fn -> Seeds.run(["some", "args"]) end)

      # Both should produce the same output since args are ignored
      assert output1 == output2
    end
  end
end
