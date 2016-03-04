# Elixir + GraphQL + Relay TodoMVC Example App

TODO:
[ ] Fix response from marking all todos (Read Relay documentation about mutations: http://facebook.github.io/relay/docs/guides-mutations.html#content)
[ ] Fix completed tasks showing when Active filter is selected (works on page reload)

```bash
$ mix deps.get
$ mix ecto.create && mix ecto.migrate
$ mix run priv/repo/seeds.exs
$ npm install
$ mix phoenix.server
```

Built with <a href="https://github.com/facebook/relay/tree/master/examples/todo">Facebook's Relay TodoMVC example</a> as a base.

## Troubleshooting

If you get the error:

```
** (Mix) The database for Todo.Repo couldn't be created, reason given: psql: FATAL:  role "postgres" does not exist
```

You need to either update `config/dev.exs` with valid PostgreSQL credentials or add a `postgres` user/role to your PostgreSQL installation by running `createuser -s postgres` from your CLI.
