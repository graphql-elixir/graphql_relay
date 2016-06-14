defmodule GraphQL.Relay do
  require Logger

  @moduledoc """
  Elixir library containing helpers for making a GraphQL server Relay compliant.
  """

  @spec resolve_maybe_thunk(fun | map) :: %{}
  def resolve_maybe_thunk(thing_or_thunk) do
    if Kernel.is_function(thing_or_thunk) do
      thing_or_thunk.()
    else
      thing_or_thunk
    end
  end

  def generate_schema_json! do
    Logger.debug "Updating GraphQL schema.json"

    data_dir = Application.fetch_env!(:graphql_relay, :schema_json_path)

    File.mkdir_p!(data_dir)
    File.write!(Path.join(data_dir, "schema.json"), introspect)
  end

  def introspect do
    schema_module = Application.fetch_env!(:graphql_relay, :schema_module)
    {_, data} = GraphQL.execute(apply(schema_module, :schema, []), GraphQL.Type.Introspection.query)
    Poison.encode!(data, pretty: true)
  end
end
