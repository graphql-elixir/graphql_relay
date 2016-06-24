defmodule EctoTest.Repo do
  use Ecto.Repo, otp_app: :graphql_relay, adapter: Ecto.Adapters.Postgres
end
