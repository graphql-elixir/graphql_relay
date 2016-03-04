defmodule Todo.GraphQL.Schema.User do
  alias GraphQL.Type.Int
  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.String
  alias GraphQL.Relay.Node
  alias GraphQL.Relay.Connection

  alias Todo.GraphQL.Schema.Root
  alias Todo.Repo

  import Ecto.Query

  def type do
    %ObjectType{
      name: "User",
      description: "The user",
      fields: %{
        id: Node.global_id_field("user"),
        name: %{type: %String{}},
        email: %{type: %String{}},
        todos: %{
          type: Todo.GraphQL.Schema.Todo.connection[:connection_type],
          description: "The todos this user owns",
          args: Map.merge(
            %{status: %{type: %String{}, defaultValue: "any"}},
            Connection.args
          ),
          resolve: fn(user, args, _ctx) ->
            args = Map.put(args, :repo, Repo)
            query = Ecto.assoc(user, :todos)
            query = case args do
              %{status: "active"} -> from things in query, where: things.complete == false
              %{status: "completed"} -> from things in query, where: things.complete == true
              _ -> query
            end
            Connection.Ecto.resolve(query, args)
          end
        },
        totalCount: %{
          type: %Int{},
          resolve: fn(user, _args, _info) ->
            Connection.Ecto.connection_count(Repo, Ecto.assoc(user, :todos))
          end
        },
        completedCount: %{
          type: %Int{},
          resolve: fn(user, _args, _info) ->
            query = Ecto.assoc(user, :todos)
            completed_query = from things in query, where: things.complete == true
            completed_count_query = from things in completed_query, select: count(things.id)
            Repo.one(completed_count_query)
          end
        }
      },
      interfaces: [Root.node_interface]
    }
  end

  def find(id) do
    Todo.User
      |> preload(:todos)
      |> Repo.get(id)
  end

  defmodule Mutations do
  end
end
