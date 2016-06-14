defmodule Mix.Tasks.Graphql.Gen.SchemaJson do
  use Mix.Task

  @shortdoc "Generates a `schema.json` file"

  @moduledoc """
  Creates/updates the GraphQL `schema.json` file.

      mix graphql.gen.schema_json --build brunch

  You can specify which build system you want to trigger a rebuild for.
  If no build system is specified then no build is triggered.

  ## Command line

    * `--build` - Rebuild the JavaScript. Can be set to one of either:

      * `brunch` - use Brunch. This is the Phoenix default build system.

      * `webpack` - use Webpack

  """

  @doc false
  @spec run(OptionParser.argv) :: :ok
  def run(args) do
    case OptionParser.parse!(args, strict: [build: :string]) do
      {[], []} ->
        GraphQL.Relay.generate_schema_json!
      {[build: build_system], []} ->
        case build_system do
          "brunch"  ->
            GraphQL.Relay.generate_schema_json!
            System.cmd "brunch", ["build"]
          "webpack" ->
            GraphQL.Relay.generate_schema_json!
            System.cmd "webpack", ["-p"]
          _ ->
            Mix.raise("`#{build_system}` is not currently supported.")
        end
      {_, _} ->
        Mix.raise("Invalid options")
    end
  end
end
