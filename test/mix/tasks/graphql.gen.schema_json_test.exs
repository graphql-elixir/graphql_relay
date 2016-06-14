Code.require_file "../../support/star_wars/data.exs", __DIR__
Code.require_file "../../support/star_wars/schema.exs", __DIR__

defmodule Mix.Tasks.Graphql.Gen.SchemaJsonTest do
  use ExUnit.Case, async: true

  test "fails when invalid options given" do
    assert_raise Mix.Error, "Invalid options", fn ->
      Mix.Tasks.Graphql.Gen.SchemaJson.run(["invalid"])
    end
  end

  test "generates schema.json" do
    Mix.Tasks.Graphql.Gen.SchemaJson.run([])
    assert File.read!("priv/graphql/schema.json") == GraphQL.Relay.introspect
  end

  # test "generates schema.json" do
  #   Mix.Tasks.Graphql.Gen.SchemaJson.run([])
  #   assert File.read!("priv/graphql/schema.json") == GraphQL.Relay.introspect
  # end
end
