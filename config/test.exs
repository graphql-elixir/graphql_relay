use Mix.Config

# Ecto v1.x
# config :graphql_relay, app_repo: EctoTest.Repo

# Ecto v2.x
config :graphql_relay, ecto_repos: [EctoTest.Repo]

config :graphql_relay, EctoTest.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "graphql_relay_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
