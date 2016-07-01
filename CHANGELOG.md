# Changelog

## 0.5.0 (2016-07-01)

* Add `ordered_by` and `ordered_by_direction` options for Ecto connections so we can sort a connection by field.

## 0.4.0 (2016-06-22)

* Update optional dependency for Ecto to support both Ecto v1.x and v2.x.
* Add `GraphQL.Relay.Connection.Ecto.resolve/3` and include deprecation warning for `GraphQL.Relay.Connection.Ecto.resolve/2`. It makes no sense to add your Ecto Repo to `args`. You can now pass it directly as the first argument, which makes much more sense. `GraphQL.Relay.Connection.Ecto.resolve(Repo, query)` not `GraphQL.Relay.Connection.Ecto.resolve(query, %{repo: Repo})`.

## 0.3.0 (2016-06-09)

* Bump version to match GraphQL Elixir
* Update dependencies to v0.3 of GraphQL Elixir
