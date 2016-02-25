defmodule GraphQL.Relay.Node.GlobalTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  alias GraphQL.Schema
  alias GraphQL.Type.Int
  alias GraphQL.Type.List
  alias GraphQL.Type.ObjectType

  alias GraphQL.Relay.Node

  defmodule TestSchema do
    def user_data do
      %{
        "1": %{id: 1, name: "John Doe"},
        "2": %{id: 2, name: "Jane Smith"}
      }
    end

    def photo_data do
      %{
        "1": %{photoId: 1, width: 300},
        "2": %{photoId: 2, width: 400}
      }
    end

    def post_data do
      %{
        "1": %{id: 1, text: "lorem"},
        "2": %{id: 2, text: "ipsum"}
      }
    end

    def node_interface do
      Node.define_interface(fn(obj) ->
        case obj do
          %{name: _name} ->
            TestSchema.user_type
          %{photoId: _photoId} ->
            TestSchema.photo_type
          _ ->
            TestSchema.post_type
        end
      end)
    end

    def node_field do
      Node.define_field(TestSchema.node_interface, fn(_item, args, _ctx) ->
        [type, id] = Node.from_global_id(args[:id])
        key = String.to_atom(id)
        data = apply(TestSchema, String.to_atom(String.downcase("#{type}_data")), [])
        Map.get(data, key)
      end)
    end

    def user_type do
      %ObjectType{
        name: "User",
        fields: %{
          id: Node.global_id_field("User"),
          name: %{type: %GraphQL.Type.String{}}
        },
        interfaces: [node_interface]
      }
    end

    def photo_type do
      %ObjectType{
        name: "Photo",
        fields: %{
          id: Node.global_id_field("Photo", fn(obj, _args, _info) ->
            obj[:photoId]
          end),
          width: %{type: %Int{}},
        },
        interfaces: [node_interface]
      }
    end

    def post_type do
      %ObjectType{
        name: "Post",
        fields: %{
          id: Node.global_id_field,
          text: %{type: %GraphQL.Type.String{}},
        },
        interfaces: [node_interface]
      }
    end

    def query do
      %ObjectType{
        name: "Query",
        fields: %{
          node: node_field,
          allObjects: %{
            type: %List{ofType: node_interface},
            resolve: fn (_, _, _) ->
              [
                TestSchema.user_data[:"1"],
                TestSchema.user_data[:"2"],
                TestSchema.photo_data[:"1"],
                TestSchema.photo_data[:"2"],
                TestSchema.post_data[:"1"],
                TestSchema.post_data[:"2"]
              ]
            end
          }
        }
      }
    end

    def schema, do: %Schema{query: query}
  end

  test "gives different IDs" do
    query = """
      {
        allObjects {
          id
        }
      }
    """
    expected = %{
      allObjects: [
        %{
          id: "VXNlcjox"
        },
        %{
          id: "VXNlcjoy"
        },
        %{
          id: "UGhvdG86MQ=="
        },
        %{
          id: "UGhvdG86Mg=="
        },
        %{
          id: "UG9zdDox"
        },
        %{
          id: "UG9zdDoy"
        },
      ]
    }
    assert_execute({query, TestSchema.schema}, expected)
  end

  test "refetches the IDs" do
    query = """
      {
        user: node(id: "VXNlcjox") {
          id
          ... on User {
            name
          }
        },
        photo: node(id: "UGhvdG86MQ==") {
          id
          ... on Photo {
            width
          }
        },
        post: node(id: "UG9zdDox") {
          id
          ... on Post {
            text
          }
        }
      }
    """
    expected = %{
      user: %{
        id: "VXNlcjox",
        name: "John Doe"
      },
      photo: %{
        id: "UGhvdG86MQ==",
        width: 300
      },
      post: %{
        id: "UG9zdDox",
        text: "lorem"
      }
    }
    assert_execute({query, TestSchema.schema}, expected)
  end
end
