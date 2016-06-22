defmodule GraphQL.Relay.Mixfile do
  use Mix.Project

  @version "0.3.0"
  @description "Relay helpers for GraphQL Elixir"
  @repo_url "https://github.com/graphql-elixir/graphql_relay"

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
      applications: [:logger, :ecto],
      env: [
        schema_module: StarWars.Schema, # Module with a .schema function that returns your GraphQL schema
        schema_json_path: "./schema.json"
      ]
    ]
  end

  defp deps do
    [
      {:graphql, "~> 0.3"},
      {:poison, "~> 1.5 or ~> 2.0"}, # For .generate_schema_json!
      {:ecto, "~> 1.0 or ~> 2.0", optional: true, only: [:dev, :test]},
      {:postgrex, ">= 0.0.0", only: [:dev, :test]},
    ]
  end

  defp package do
    [maintainers: ["Sean Abrahams", "Josh Price"],
     licenses: ["BSD"],
     links: %{"GitHub" => @repo_url},
     files: ~w(lib mix.exs *.md LICENSE)]
  end
end
