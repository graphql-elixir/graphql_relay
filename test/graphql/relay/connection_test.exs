defmodule GraphQL.Relay.ConnectionTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  alias GraphQL.Schema
  alias GraphQL.Type.Int
  alias GraphQL.Type.ObjectType

  alias GraphQL.Relay.Connection

  defmodule TestSchema do
    def all_users do
      [
        %{ name: "Dan", friends: [ 1, 2, 3, 4 ] },
        %{ name: "Nick", friends: [ 0, 2, 3, 4 ] },
        %{ name: "Lee", friends: [ 0, 1, 3, 4 ] },
        %{ name: "Joe", friends: [ 0, 1, 2, 4 ] },
        %{ name: "Tim", friends: [ 0, 1, 2, 3 ] }
      ]
    end

    def user_type do
      %ObjectType{
        name: "User",
        fields: quote do %{
          name: %{
            type: %GraphQL.Type.String{}
          },
          friends: %{
            type: TestSchema.friend_connection[:connection_type],
            args: Connection.args,
            resolve: fn(user, args, _ctx) ->
              Connection.List.resolve(user[:friends], args)
            end
          },
          friendsForward: %{
            type: TestSchema.user_connection[:connection_type],
            args: Connection.forward_args,
            resolve: fn(user, args, _ctx) ->
              Connection.List.resolve(user[:friends], args)
            end
          },
          friendsBackward: %{
            type: TestSchema.user_connection[:connection_type],
            args: Connection.backward_args,
            resolve: fn(user, args, _ctx) ->
              Connection.List.resolve(user[:friends], args)
            end
          }
        } end
      }
    end

    def friend_connection do
      %{
        name: "Friend",
        node_type: TestSchema.user_type,
        edge_fields: %{
          friendshipTime: %{
            type: %GraphQL.Type.String{},
            resolve: fn(_obj, _args, _ctx) -> "Yesterday" end
          }
        },
        connection_fields: %{
          totalCount: %{
            type: %Int{},
            resolve: fn(_obj, _args, _ctx) -> length(TestSchema.all_users) - 1 end
          }
        },
        resolve_node: fn(edge, _, _) -> Enum.at(TestSchema.all_users, edge[:node]) end
      } |> Connection.new
    end

    def user_connection do
      %{
        node_type: TestSchema.user_type,
        resolve_node: fn(edge, _, _) -> Enum.at(TestSchema.all_users, edge[:node]) end
      } |> Connection.new
    end

    def query do
      %ObjectType{
        name: "Query",
        fields: %{
          user: %{
            type: TestSchema.user_type,
            resolve: fn(_obj, _args, _ctx) -> Enum.at(TestSchema.all_users, 0) end
          }
        }
      }
    end
    def schema, do: %Schema{query: query}
  end

  test "connection definition includes connection and edge fields" do
    query = """
      query FriendsQuery {
        user {
          friends(first: 2) {
            totalCount
            edges {
              friendshipTime
              node {
                name
              }
            }
          }
        }
      }
    """
    expected = %{
      user: %{
        friends: %{
          totalCount: 4,
          edges: [
            %{
              friendshipTime: "Yesterday",
              node: %{
                name: "Nick"
              }
            },
            %{
              friendshipTime: "Yesterday",
              node: %{
                name: "Lee"
              }
            }
          ]
        }
      }
    }
    assert_execute({query, TestSchema.schema}, expected)
  end

  test "connection definition works with forward_connection_args" do
    query = """
      query FriendsQuery {
        user {
          friendsForward(first: 2) {
            edges {
              node {
                name
              }
            }
          }
        }
      }
    """
    expected = %{
      user: %{
        friendsForward: %{
          edges: [
            %{
              node: %{
                name: "Nick"
              }
            },
            %{
              node: %{
                name: "Lee"
              }
            }
          ]
        }
      }
    }
    assert_execute({query, TestSchema.schema}, expected)
  end

  test "connection definition works with backward_connection_args" do
    query = """
      query FriendsQuery {
        user {
          friendsBackward(last: 2) {
            edges {
              node {
                name
              }
            }
          }
        }
      }
    """
    expected = %{
      user: %{
        friendsBackward: %{
          edges: [
            %{
              node: %{
                name: "Joe"
              }
            },
            %{
              node: %{
                name: "Tim"
              }
            }
          ]
        }
      }
    }
    assert_execute({query, TestSchema.schema}, expected)
  end
end
