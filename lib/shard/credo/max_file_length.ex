if Code.ensure_loaded?(Credo.Check) do
  defmodule Shard.Credo.MaxFileLength do
    @moduledoc """
      Checks all lines for a given Regex.

      This is fun!
    """

    @default_params [
      # our check will find this line.
      max_lines: 400
    ]

    # you can configure the basics of your check via the `use Credo.Check` call
    use Credo.Check, base_priority: :high, category: :custom, exit_status: 1

    @doc false
    @impl true
    def run(%SourceFile{} = source_file, params) do
      max_lines = params |> Params.get(:max_lines, __MODULE__)

      lines = SourceFile.lines(source_file)
      count = length(lines)

      # IssueMeta helps us pass down both the source_file and params of a check
      # run to the lower levels where issues are created, formatted and returned
      issue_meta = IssueMeta.for(source_file, params)

      if count > max_lines do
        issue =
          format_issue(issue_meta,
            message: "File is too long: #{count} lines > max of #{max_lines}",
            trigger: source_file.filename
          )

        [issue]
      else
        []
      end
    end
  end
end
