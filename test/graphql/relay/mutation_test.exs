defmodule GraphQL.Relay.MutationTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  alias GraphQL.Schema
  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.Int

  alias GraphQL.Relay.Mutation

  defmodule TestSchema do
    def simple_mutation do
      Mutation.new(%{
        name: "SimpleMutation",
        input_fields: %{},
        output_fields: %{
          result: %{type: %Int{}}
        },
        mutate_and_get_payload: fn(_input, _info) -> %{result: 1} end
      })
    end

    def simple_mutation_with_thunk_fields do
      Mutation.new(%{
        name: "SimpleMutationWithThunkFields",
        input_fields: fn() -> %{inputData: %{type: %Int{}}} end,
        output_fields: fn() -> %{result: %{type: %Int{}}} end,
        mutate_and_get_payload: fn(input, _info) -> %{result: input[:inputData]} end
      })
    end

    def mutation do
      %ObjectType{
        name: "Mutation",
        fields: %{
          simpleMutation: simple_mutation,
          simpleMutationWithThunkFields: simple_mutation_with_thunk_fields
        }
      }
    end

    def schema, do: %Schema{query: mutation, mutation: mutation}
  end

  # TODO: This relies on validation which is not yet implemented
  # in the GraphQL library.
  @tag :skip
  test "Mutations require arguments" do
    query = """
      mutation M {
        simpleMutation {
          result
        }
      }
    """
    expected = [%{message: "Field \"simpleMutation\" argument \"input\" of type \"SimpleMutationInput!\" is required but not provided.", line_number: 1}]
    assert_execute_error({query, TestSchema.schema}, expected)
  end

  test "Mutations with a clientMutationId return the same clientMutationID" do
    query = """
      mutation M {
        simpleMutation(input: {clientMutationId: "abc"}) {
          result
          clientMutationId
        }
      }
    """
    expected = %{
      simpleMutation: %{
        result: 1,
        clientMutationId: "abc"
      }
    }
    assert_execute({query, TestSchema.schema}, expected)
  end

  test "Thunks as input and output fields" do
    query = """
      mutation M {
        simpleMutationWithThunkFields(input: {inputData: 1234, clientMutationId: "abc"}) {
          result
          clientMutationId
        }
      }
    """
    expected = %{
      simpleMutationWithThunkFields: %{
        result: 1234,
        clientMutationId: "abc"
      }
    }
    assert_execute({query, TestSchema.schema}, expected)
  end

  test "introspection: contains correct input" do
    query = """
      {
        __type(name: "SimpleMutationInput") {
          name
          kind
          inputFields {
            name
            type {
              name
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
        name: "SimpleMutationInput",
        kind: "INPUT_OBJECT",
        inputFields: [
          %{
            name: "clientMutationId",
            type: %{
              name: nil,
              kind: "NON_NULL",
              ofType: %{
                name: "String",
                kind: "SCALAR"
              }
            }
          }
        ]
      }
    }
    assert_execute({query, TestSchema.schema}, expected)
  end

  test "introspection: contains correct payload" do
    query = """
      {
        __type(name: "SimpleMutationPayload") {
          name
          kind
          fields {
            name
            type {
              name
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
        name: "SimpleMutationPayload",
        kind: "OBJECT",
        fields: [
          %{
            name: "clientMutationId",
            type: %{
              name: nil,
              kind: "NON_NULL",
              ofType: %{
                name: "String",
                kind: "SCALAR"
              }
            }
          },
          %{
            name: "result",
            type: %{
              name: "Int",
              kind: "SCALAR",
              ofType: nil
            }
          }
        ]
      }
    }
    assert_execute({query, TestSchema.schema}, expected)
  end

  test "introspection: contains correct field" do
    query = """
      {
        __schema {
          mutationType {
            fields {
              name
              args {
                name
                type {
                  name
                  kind
                  ofType {
                    name
                    kind
                  }
                }
              }
              type {
                name
                kind
              }
            }
          }
        }
      }
    """
    expected = %{
      __schema: %{
        mutationType: %{
          fields: [
            %{
              name: "simpleMutation",
              args: [
                %{
                  name: "input",
                  type: %{
                    name: nil,
                    kind: "NON_NULL",
                    ofType: %{
                      name: "SimpleMutationInput",
                      kind: "INPUT_OBJECT"
                    }
                  },
                }
              ],
              type: %{
                name: "SimpleMutationPayload",
                kind: "OBJECT",
              }
            },
            %{
              name: "simpleMutationWithThunkFields",
              args: [
                %{
                  name: "input",
                  type: %{
                    name: nil,
                    kind: "NON_NULL",
                    ofType: %{
                      name: "SimpleMutationWithThunkFieldsInput",
                      kind: "INPUT_OBJECT"
                    }
                  },
                }
              ],
              type: %{
                name: "SimpleMutationWithThunkFieldsPayload",
                kind: "OBJECT",
              }
            }
          ]
        }
      }
    }

    assert_execute({query, TestSchema.schema}, expected)
  end
end
