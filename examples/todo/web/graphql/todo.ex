defmodule Todo.GraphQL.Schema.Todo do
  import Ecto.Query

  alias GraphQL.Type.Boolean
  alias GraphQL.Type.ID
  alias GraphQL.Type.List
  alias GraphQL.Type.NonNull
  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.String

  alias GraphQL.Relay.Connection
  alias GraphQL.Relay.Mutation
  alias GraphQL.Relay.Node

  alias Todo.GraphQL.Schema.Root
  alias Todo.GraphQL.Schema.User
  alias Todo.Repo

  def connection do
    %{
      name: "Todo",
      node_type: type,
      edge_fields: %{},
      connection_fields: %{},
      resolve_node: nil,
      resolve_cursor: nil
    } |> Connection.new
  end

  def type do
    %ObjectType{
      name: "Todo",
      description: "A task todo",
      fields: %{
        id: Node.global_id_field("todo"),
        text: %{
          type: %String{},
          resolve: fn(obj, _args, _info) -> obj.text end
        },
        complete: %{
          type: %Boolean{},
          resolve: fn(obj, _args, _info) -> obj.complete end
        },
      },
      interfaces: [Root.node_interface]
    }
  end

  def find(id) do
    Repo.get!(Elixir.Todo.Todo, id)
  end

  def find_todos() do
  end

  def create(params) do
    todo_params = Map.merge(params, %{ "user_id" => 1})
    changeset = Elixir.Todo.Todo.changeset(%Elixir.Todo.Todo{}, todo_params)

    case Repo.insert(changeset) do
      {:ok, todo} ->
        todo
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update(id, params) do
    todo_params = Map.merge(params, %{ "user_id" => 1})
    todo = Repo.get!(Elixir.Todo.Todo, id)
    changeset = Elixir.Todo.Todo.changeset(todo, todo_params)

    case Repo.update(changeset) do
      {:ok, todo} ->
        todo
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_all(user_id, todo_params) do
    Elixir.Todo.Todo
      |> where(user_id: ^user_id)
      |> Repo.update_all(set: todo_params)

    Elixir.Todo.Todo
      |> where(user_id: ^user_id)
      |> Repo.all
  end

  def delete(id) do
    todo = Repo.get_by!(Elixir.Todo.Todo, id: id)
    Repo.delete!(todo)
  end

  def delete_completed(user_id) do
    todos = Elixir.Todo.Todo
      |> where(complete: true)
      |> where(user_id: ^user_id)
      |> Repo.all

    Elixir.Todo.Todo
      |> where(complete: true)
      |> where(user_id: ^user_id)
      |> Repo.delete_all

    todos
  end

  defmodule Mutations do
    alias Todo.GraphQL.Schema.User

    def add do
      %{
        name: "AddTodo",
        input_fields: %{
          text: %{type: %NonNull{ofType: %String{}}},
        },
        output_fields: %{
          todoEdge: %{
            type: Todo.GraphQL.Schema.Todo.connection[:edge_type],
            resolve: fn(obj, _args, _info) ->
              todo = Todo.GraphQL.Schema.Todo.find(obj[:id])
              %{
                cursor: GraphQL.Relay.Connection.Ecto.cursor_for_object_in_connection(todo),
                node: todo
              }
            end
          },
          viewer: %{
            type: User.type,
            resolve: fn(_obj, _args, _info) ->
              User.find(1)
            end
          },
        },
        mutate_and_get_payload: fn(input, _info) ->
          todo = Todo.GraphQL.Schema.Todo.create(input)
          %{
            id: todo.id,
          }
        end
      } |> Mutation.new
    end

    def change_status do
      %{
        name: "ChangeTodoStatus",
        input_fields: %{
          complete: %{type: %NonNull{ofType: %Boolean{}}},
          id: %{type: %NonNull{ofType: %ID{}}},
        },
        output_fields: %{
          todo: %{
            type: Todo.GraphQL.Schema.Todo.type,
            resolve: fn (obj, _args, _info) ->
              Todo.GraphQL.Schema.Todo.find(obj[:id])
            end
          },
          viewer: %{
            type: User.type,
            resolve: fn(_obj, _args, _info) ->
              User.find(1)
            end
          },
        },
        mutate_and_get_payload: fn(input, _info) ->
          [_, id] = Node.from_global_id(input["id"])
          todo = Todo.GraphQL.Schema.Todo.update(id, input)
          %{
            id: todo.id,
          }
        end
      } |> Mutation.new
    end

    def mark_all do
      %{
        name: "MarkAllTodos",
        input_fields: %{
          complete: %{type: %NonNull{ofType: %Boolean{}}},
          user_id: %{type: %NonNull{ofType: %ID{}}}
        },
        output_fields: %{
          changedTodos: %{
            type: %List{ofType: Todo.GraphQL.Schema.Todo.type},
            resolve: fn (obj, _args, _info) ->
              Enum.map(obj[:ids], & Node.to_global_id("todo", &1))
            end
          },
          viewer: %{
            type: User.type,
            resolve: fn(_obj, _args, _info) ->
              User.find(1)
            end
          },
        },
        mutate_and_get_payload: fn(input, _info) ->
          todos = Todo.GraphQL.Schema.Todo.update_all(1, [complete: input["complete"]])
          %{
            ids: Enum.map(todos, & &1.id)
          }
        end
      } |> Mutation.new
    end

    def remove_completed do
      %{
        name: "RemoveCompletedTodos",
        input_fields: %{
          user_id: %{type: %NonNull{ofType: %ID{}}}
        },
        output_fields: %{
          deletedTodoIds: %{
            type: %List{ofType: %String{}},
            resolve: fn (obj, _args, _info) ->
              Enum.map(obj[:ids], & Node.to_global_id("todo", &1))
            end
          },
          viewer: %{
            type: User.type,
            resolve: fn(_obj, _args, _info) ->
              User.find(1)
            end
          },
        },
        mutate_and_get_payload: fn(input, _info) ->
          [_, user_id] = Node.from_global_id(input["viewer"]["id"])
          todos = Todo.GraphQL.Schema.Todo.delete_completed(user_id)
          %{
            ids: Enum.map(todos, & &1.id)
          }
        end
      } |> Mutation.new
    end

    def remove do
      %{
        name: "RemoveTodo",
        input_fields: %{
          id: %{type: %NonNull{ofType: %ID{}}},
        },
        output_fields: %{
          deletedTodoId: %{
            type: %ID{},
            resolve: fn (obj, _args, _info) ->
              Node.to_global_id("todo", obj[:id])
            end
          },
          viewer: %{
            type: User.type,
            resolve: fn(_obj, _args, _info) ->
              User.find(1)
            end
          },
        },
        mutate_and_get_payload: fn(input, _info) ->
          [_, id] = Node.from_global_id(input["id"])
          todo = Todo.GraphQL.Schema.Todo.delete(id)
          %{
            id: todo.id,
          }
        end
      } |> Mutation.new
    end

    def rename do
      %{
        name: "RenameTodo",
        input_fields: %{
          id: %{type: %NonNull{ofType: %ID{}}},
          text: %{type: %NonNull{ofType: %String{}}},
        },
        output_fields: %{
          todo: %{
            type: Todo.GraphQL.Schema.Todo.type,
            resolve: fn (obj, _args, _info) ->
              Todo.GraphQL.Schema.Todo.find(obj[:id])
            end
          },
          viewer: %{
            type: User.type,
            resolve: fn(_obj, _args, _info) ->
              User.find(1)
            end
          },
        },
        mutate_and_get_payload: fn(input, _info) ->
          [_, id] = Node.from_global_id(input["id"])
          todo = Todo.GraphQL.Schema.Todo.update(id, input)
          %{
            id: todo.id,
          }
        end
      } |> Mutation.new
    end
  end
end
