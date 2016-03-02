defmodule GraphQL.Relay.Connection do
  @doc """
  Any type whose name ends in "Connection" is considered by Relay to be a
  Connection Type. Connection types must be an "Object" as defined in the
  "Type System" section of the GraphQL Specification.

  Connection types must have fields named edges and pageInfo. They may have
  additional fields related to the connection, as the schema designer sees fit.

  https://facebook.github.io/relay/graphql/connections.htm#sec-Connection-Types
  """
  alias GraphQL.Type.Boolean
  alias GraphQL.Type.Int
  alias GraphQL.Type.NonNull
  alias GraphQL.Type.ObjectType

  def new(config) do
    node_type = config[:node_type]

    name = config[:name] || Map.get(node_type, :name)
    edge_fields = config[:edge_fields] || %{}
    connection_fields = config[:connection_fields] || %{}
    resolve_node = config[:resolve_node]
    resolve_cursor = config[:resolve_cursor]

    edge_type = %ObjectType{
      name: "#{name}Edge",
      description: "An edge in a connection.",
      fields: Map.merge(GraphQL.Relay.resolve_maybe_thunk(edge_fields), %{
        node: %{
          type: node_type,
          description: "The item at the end of the edge",
          resolve: resolve_node
        },
        cursor: %{
          type: %NonNull{ofType: %GraphQL.Type.String{}},
          description: "A cursor for use in pagination",
          resolve: resolve_cursor
        }
      })
    }

    connection_type = %ObjectType{
      name: "#{name}Connection",
      description: "A connection to a list of items.",
      fields: Map.merge(GraphQL.Relay.resolve_maybe_thunk(connection_fields), %{
        edges: %{
          type: %GraphQL.Type.List{ofType: edge_type},
          description: "Information to aid in pagination."
        },
        pageInfo: %{
          type: %NonNull{ofType: page_info},
          description: "Information to aid in pagination."
        },
      })
    }

    %{edge_type: edge_type, connection_type: connection_type}
  end

  def args(additional_args \\ %{}) do
    Map.merge(forward_args, backward_args)
      |> Map.merge(additional_args)
  end

  def forward_args do
    %{
      "after": %{type: %GraphQL.Type.String{}},
      first: %{type: %Int{}}
    }
  end

  def backward_args do
    %{
      before: %{type: %GraphQL.Type.String{}},
      last: %{type: %Int{}}
    }
  end

  def page_info do
    %ObjectType{
      name: "PageInfo",
      description: "Information about pagination in a connection.",
      fields: %{
        hasNextPage: %{
          type: %NonNull{ofType: %Boolean{}},
          description: "When paginating forwards, are there more items?"
        },
        hasPreviousPage: %{
          type: %NonNull{ofType: %Boolean{}},
          description: "When paginating backwards, are there more items?"
        },
        startCursor: %{
          type: %GraphQL.Type.String{},
          description: "When paginating backwards, the cursor to continue."
        },
        endCursor: %{
          type: %GraphQL.Type.String{},
          description: "When paginating forwards, the cursor to continue."
        }
      }
    }
  end
end
