defmodule GraphQL.Relay.Node.PluralTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  alias GraphQL.Schema
  alias GraphQL.Type.ObjectType

  alias GraphQL.Relay.Node

  defmodule TestSchema do
    def user_type do
      %ObjectType{
        name: "User",
        fields: %{
          username: %{type: %GraphQL.Type.String{}},
          url: %{type: %GraphQL.Type.String{}}
        }
      }
    end

    def query do
      %ObjectType{
        name: "Query",
        fields: %{
          usernames: Node.plural_identifying_root_field(%{
            arg_name: "usernames",
            description: "Map from a username to the user",
            input_type: %GraphQL.Type.String{},
            output_type: TestSchema.user_type,
            resolve_single_input: fn(username, args) ->
              %{
                username: username,
                url: "www.facebook.com/#{username}?lang=#{args[:root_value][:lang]}"
              }
            end
          })
        }
      }
    end

    def root_value do
      %{
        lang: "en"
      }
    end

    def schema, do: %Schema{query: query}
  end

  test "fetching" do
    query = """
      {
        usernames(usernames:["dschafer", "leebyron", "schrockn"]) {
          username
          url
        }
      }
    """
    expected = %{
      usernames: [
        %{
          username: "dschafer",
          url: "www.facebook.com/dschafer?lang=en"
        },
        %{
          username: "leebyron",
          url: "www.facebook.com/leebyron?lang=en"
        },
        %{
          username: "schrockn",
          url: "www.facebook.com/schrockn?lang=en"
        },
      ]
    }
    assert_execute({query, TestSchema.schema, TestSchema.root_value}, expected)
  end

  test "refetches the IDs" do
    query = """
      {
        __schema {
          queryType {
            fields {
              name
              args {
                name
                type {
                  kind
                  ofType {
                    kind
                    ofType {
                      kind
                      ofType {
                        name
                        kind
                      }
                    }
                  }
                }
              }
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
    """
    expected = %{
      __schema: %{
        queryType: %{
          fields: [
            %{
              name: "usernames",
              args: [
                %{
                  name: "usernames",
                  type: %{
                    kind: "NON_NULL",
                    ofType: %{
                      kind: "LIST",
                      ofType: %{
                        kind: "NON_NULL",
                        ofType: %{
                          name: "String",
                          kind: "SCALAR",
                        }
                      }
                    }
                  }
                }
              ],
              type: %{
                kind: "LIST",
                ofType: %{
                  name: "User",
                  kind: "OBJECT",
                }
              }
            }
          ]
        }
      }
    }
    assert_execute({query, TestSchema.schema}, expected)
  end
end
