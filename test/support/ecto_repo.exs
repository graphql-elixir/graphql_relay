defmodule EctoTest do
  defmodule Repo do
    use Ecto.Repo, otp_app: :graphql_relay, adapter: Sqlite.Ecto
  end
end
