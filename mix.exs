defmodule GraphQL.Relay.Mixfile do
  use Mix.Project

  @version "0.0.9"
  @description "Elixir implementation of Relay for GraphQL"
  @repo_url "https://github.com/graphql-elixir/graphql-relay-elixir"

  def project do
    [app: :graphql_relay,
     version: @version,
     elixir: "~> 1.2",
     description: @description,
     package: package,
     source_url: @repo_url,
     homepage_url: @repo_url,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     name: "GraphQL.Relay",
     docs: [main: "README", extras: ["README.md"]]]
  end

  def application do
    [
      applications: [:logger],
      env: [
        schema_module: StarWars.Schema, # Module with a .schema function that returns your GraphQL schema
        schema_json_path: "./schema.json"
      ]
    ]
  end

  defp deps do
    [
      {:graphql, git: "https://github.com/graphql-elixir/graphql-elixir.git"},
      {:poison, "~> 1.5 or ~> 2.0"}, # For .generate_schema_json!
      {:ecto, "~> 1.1.4", optional: true},
      {:sqlite_ecto, "~> 1.0.0", only: [:dev, :test]},
    ]
  end

  defp package do
    [maintainers: ["Sean Abrahams"],
     licenses: ["MIT"],
     links: %{"GitHub" => @repo_url},
     files: ~w(lib mix.exs *.md LICENSE)]
  end
end
