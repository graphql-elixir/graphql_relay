defmodule GraphQL.Relay.NodeTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  alias GraphQL.Schema
  alias GraphQL.Type.ID
  alias GraphQL.Type.Int
  alias GraphQL.Type.NonNull
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
        "3": %{id: 3, width: 300},
        "4": %{id: 4, width: 400}
      }
    end

    def node_interface do
      Node.define_interface(fn(obj) ->
        key = String.to_atom(Integer.to_string(obj[:id]))
        if Map.get(TestSchema.user_data, key) do
          TestSchema.user_type
        else
          TestSchema.photo_type
        end
      end)
    end

    def node_field do
      Node.define_field(TestSchema.node_interface, fn(_item, args, _ctx) ->
        key = String.to_atom(args[:id])
        if Map.get(TestSchema.user_data, key) do
          Map.get(TestSchema.user_data, key)
        else
          Map.get(TestSchema.photo_data, key)
        end
      end)
    end

    def user_type do
      %ObjectType{
        name: "User",
        fields: %{
          id: %{type: %NonNull{ofType: %ID{}}},
          name: %{type: %GraphQL.Type.String{}}
        },
        interfaces: [node_interface]
      }
    end

    def photo_type do
      %ObjectType{
        name: "Photo",
        fields: %{
          id: %{type: %NonNull{ofType: %ID{}}},
          width: %{type: %Int{}},
        },
        interfaces: [node_interface]
      }
    end

    def query do
      %ObjectType{
        name: "Query",
        fields: %{
          node: node_field
        }
      }
    end

    def schema, do: %Schema{query: query}
  end

  test "gets the correct ID for users" do
    query = """
      {
        node(id: "1") {
          id
        }
      }
    """
    expected = %{
      node: %{
        id: "1"
      }
    }
    assert_execute({query, TestSchema.schema}, expected)
  end

  test "gets the correct ID for photos" do
    query = """
      {
        node(id: "4") {
          id
        }
      }
    """
    expected = %{
      node: %{
        id: "4"
      }
    }
    assert_execute({query, TestSchema.schema}, expected)
  end

  test "gets the correct name for users" do
    query = """
       {
         node(id: "1") {
           id
           ... on User {
             name
           }
         }
       }
    """
    expected = %{
      node: %{
        id: "1",
        name: "John Doe"
      }
    }
    assert_execute({query, TestSchema.schema}, expected)
  end

  # Problem with inline fragments. Moving the attribute out of the fragment
  # works... seems like an issue with graphql-elixir?
  test "gets the correct width for photos" do
    query = """
      {
        node(id: "4") {
          id
          ... on Photo {
            width
          }
        }
      }
    """
    expected = %{
      node: %{
        id: "4",
        width: 400
      }
    }
    assert_execute({query, TestSchema.schema}, expected)
  end

  test "gets the correct type name for users" do
    query = """
      {
        node(id: "1") {
          id
          __typename
        }
      }
    """
    expected = %{
      node: %{
        id: "1",
        __typename: "User",
      }
    }
    assert_execute({query, TestSchema.schema}, expected)
  end

  test "gets the correct type name for photos" do
    query = """
      {
        node(id: "4") {
          id
          __typename
        }
      }
    """
    expected = %{
      node: %{
        id: "4",
        __typename: "Photo",
      }
    }
    assert_execute({query, TestSchema.schema}, expected)
  end

  test "ignores photo fragments on user" do
    query = """
      {
        node(id: "1") {
          id
          ... on Photo {
            width
          }
        }
      }
    """
    expected = %{
      node: %{
        id: "1",
      }
    }

    assert_execute({query, TestSchema.schema}, expected)
  end

  test "returns null for bad IDs" do
    query = """
      {
        node(id: "5") {
          id
        }
      }
    """
    expected = %{
      node: nil
    }
    assert_execute({query, TestSchema.schema}, expected)
  end

  test "introspsection has correct node interface" do
    query = """
      {
        __type(name: "Node") {
          name
          kind
          fields {
            name
            type {
              kind
              ofType {
                name
                kind
              }
            }
          }
        }
      }
    """
    expected = %{
      __type: %{
        name: "Node",
        kind: "INTERFACE",
        fields: [
          %{
            name: "id",
            type: %{
              kind: "NON_NULL",
              ofType: %{
                name: "ID",
                kind: "SCALAR"
              }
            }
          }
        ]
      }
    }
    assert_execute({query, TestSchema.schema}, expected)
  end

  test "has correct node root field" do
    query = """
      {
        __schema {
          queryType {
            fields {
              name
              type {
                name
                kind
              }
              args {
                name
                type {
                  kind
                  ofType {
                    name
                    kind
                  }
                }
              }
            }
          }
        }
      }
    """
    expected = %{
      __schema: %{
        queryType: %{
          fields: [
            %{
              name: "node",
              type: %{
                name: "Node",
                kind: "INTERFACE"
              },
              args: [
                %{
                  name: "id",
                  type: %{
                    kind: "NON_NULL",
                    ofType: %{
                      name: "ID",
                      kind: "SCALAR"
                    }
                  }
                }
              ]
            }
          ]
        }
      }
    }

    assert_execute({query, TestSchema.schema}, expected)
  end
end
