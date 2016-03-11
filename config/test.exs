use Mix.Config

# config :graphql_relay, GraphQL.Relay.Connection.EctoTest.Repo,
#   adapter: Ecto.Adapters.Postgres,
#   database: "graphql_relay_test",
#   username: "postgres",
#   password: "postgres",
#   hostname: "localhost"

config :graphql_relay, app_repo: EctoTest.Repo
config :graphql_relay, EctoTest.Repo,
  adapter: Sqlite.Ecto,
  database: ":memory:",
  pool: Ecto.Adapters.SQL.Sandbox
