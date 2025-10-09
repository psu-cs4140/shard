defmodule Mix.Tasks.Test.NoWarn do
  use Mix.Task

  @shortdoc "Run tests with warnings treated as errors (without editing test files)"
  @moduledoc """
  Sets Elixir to treat warnings as errors, then runs `mix test`.
  Useful in CI to fail when files under `test/` emit warnings.
  """

  @impl true
  def run(args) do
    Code.compiler_options(warnings_as_errors: true)
    Mix.Task.run("test", args)
  end
end
