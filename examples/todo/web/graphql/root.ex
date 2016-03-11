defmodule Todo.GraphQL.Schema.Root do
  alias GraphQL.Schema
  alias GraphQL.Type.ObjectType
  alias GraphQL.Relay.Node

  def node_interface do
    Node.define_interface(fn(obj) ->
      case obj do
        %{text: _text} ->
          Todo.GraphQL.Schema.Todo.type
        _ ->
          Todo.GraphQL.Schema.User.type
      end
    end)
  end

  def node_field do
    Node.define_field(node_interface, fn (_item, args, _ctx) ->
      [type, id] = Node.from_global_id(args[:id])
      case type do
        "todo" ->
          Todo.GraphQL.Schema.Todo.find(id)
        _ ->
          Todo.GraphQL.Schema.User.find(id)
      end
    end)
  end

  def query do
    %ObjectType{
      name: "Root",
      description: "The query root of this schema. See available queries.",
      fields: %{
        node: node_field,
        viewer: %{
          type: Todo.GraphQL.Schema.User.type,
          resolve: fn(_, _, _) -> Todo.GraphQL.Schema.User.find(1) end
        }
      }
    }
  end

  def mutation do
    %ObjectType{
      name: "Mutation",
      description: "Root object for performing data mutations",
      fields: %{
        addTodo: Todo.GraphQL.Schema.Todo.Mutations.add,
        changeTodoStatus: Todo.GraphQL.Schema.Todo.Mutations.change_status,
        markAllTodos: Todo.GraphQL.Schema.Todo.Mutations.mark_all,
        removeCompletedTodos: Todo.GraphQL.Schema.Todo.Mutations.remove_completed,
        removeTodo: Todo.GraphQL.Schema.Todo.Mutations.remove,
        renameTodo: Todo.GraphQL.Schema.Todo.Mutations.rename
      }
    }
  end

  def schema do
    %Schema{
      query: query,
      mutation: mutation
    }
  end
end
