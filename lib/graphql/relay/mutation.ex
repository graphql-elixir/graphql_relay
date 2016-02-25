defmodule GraphQL.Relay.Mutation do
  @doc """
  Relay’s support for mutations relies on the GraphQL server exposing mutation
  fields in a standardized way. These mutations accept and emit a identifier
  string, which allows Relay to track mutations and responses.

  All mutations include in their input a clientMutationId string, which is
  then returned as part of the object returned by the mutation field.

  https://facebook.github.io/relay/graphql/mutations.htm
  """
  alias GraphQL.Type.NonNull
  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.Input

  def new(config) do
    name = config[:name]
    input_fields = config[:input_fields]
    output_fields = config[:output_fields]
    mutate_and_get_payload = config[:mutate_and_get_payload]

    augmented_input_fields = Map.merge(GraphQL.Relay.resolve_maybe_thunk(input_fields), %{
      clientMutationId: %{type: %NonNull{ofType: %GraphQL.Type.String{}}}
    })

    augmented_output_fields = Map.merge(GraphQL.Relay.resolve_maybe_thunk(output_fields), %{
      clientMutationId: %{type: %NonNull{ofType: %GraphQL.Type.String{}}}
    })

    output_type = %ObjectType{
      name: "#{name}Payload",
      fields: augmented_output_fields
    }

    input_type = %Input{
      name: "#{name}Input",
      fields: augmented_input_fields
    }

    %{
      type: output_type,
      args: %{
        input: %{
          type: %NonNull{ofType: input_type}
        }
      },
      resolve: fn(_data, args, info) ->
        Map.merge(mutate_and_get_payload.(args[:input], info), %{
          clientMutationId: args[:input][:clientMutationId]
        })
      end
    }
  end
end
