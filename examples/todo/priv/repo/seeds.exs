# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Todo.Repo.insert!(%SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Todo.User

{_, user} = Todo.Repo.insert(%User{name: "Jean-Luc Picard", email: "jean-luc@ufop.org"})
Todo.Repo.insert(%Todo.Todo{user_id: user.id, text: "Learn Elixir", complete: false})
Todo.Repo.insert(%Todo.Todo{user_id: user.id, text: "Learn GraphQL", complete: false})
Todo.Repo.insert(%Todo.Todo{user_id: user.id, text: "Learn Relay", complete: false})
