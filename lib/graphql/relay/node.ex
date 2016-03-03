defmodule GraphQL.Relay.Node do
  @doc """
  Relay’s support for object identification relies on the GraphQL server exposing object identifiers in a standardized way. In the query, the schema should provide a standard mechanism for asking for an object by ID. In the response, the schema provides a standard way of providing these IDs.

  We refer to objects with identifiers as “nodes”.

  http://facebook.github.io/relay/graphql/objectidentification.htm
  """
  alias GraphQL.Type.ID
  alias GraphQL.Type.Interface
  alias GraphQL.Type.List
  alias GraphQL.Type.NonNull

  def node_definitions(type_resolver, id_fetcher) do
    node_interface = define_interface(type_resolver)
    node_field = define_field(node_interface, id_fetcher)
    {node_interface, node_field}
  end

  def define_interface(type_resolver) do
    %{
      name: "Node",
      description: "An object with an ID",
      fields: %{
        id: %{
          type: %NonNull{ofType: %ID{}},
          description: "The id of the object."
        }
      },
      resolver: type_resolver
    } |> Interface.new
  end

  def define_field(interface, id_fetcher) do
    %{
      name: "node",
      description: "Fetches an object given its ID",
      type: interface,
      args: %{
        id: %{
          type: %NonNull{ofType: %ID{}},
          description: "The ID of an object"
        }
      },
      resolve: id_fetcher
    }
  end

  def to_global_id(type, id) do
    Base.encode64("#{type}:#{id}")
  end

  @spec from_global_id(String.t()) :: []
  def from_global_id(global_id) do
    case Base.decode64(global_id) do
      {:ok, decoded} -> String.split(decoded, ":")
      :error -> [nil, nil]
    end
  end

  def global_id_field do
    %{
      name: "id",
      description: "The ID of an object",
      type: %NonNull{ofType: %ID{}},
      resolve: fn (obj, _args, info) ->
        GraphQL.Relay.Node.to_global_id(info.parent_type.name, obj.id)
      end
    }
  end

  def global_id_field(type_name) do
    Map.merge(global_id_field, %{
      resolve: fn (obj, _args, _info) ->
        GraphQL.Relay.Node.to_global_id(type_name, obj.id)
      end
    })
  end

  def global_id_field(type_name, id_fetcher) do
    Map.merge(global_id_field(type_name), %{
      resolve: fn (obj, args, info) ->
        GraphQL.Relay.Node.to_global_id(type_name, id_fetcher.(obj, args, info))
      end
    })
  end

  @spec plural_identifying_root_field(%{}) :: %{}
  def plural_identifying_root_field(config) do
    input_args = %{}
    input_args = Map.put(input_args, String.to_atom(config.arg_name), %{
      type: %NonNull{ofType: %List{ofType: %NonNull{ofType: config.input_type}}}
    })
    %{
      description: config.description,
      type: %List{ofType: config.output_type},
      args: input_args,
      resolve: fn(_obj, args, info) ->
        inputs = args[String.to_atom(config.arg_name)]
        Enum.map(inputs, fn(input) -> config.resolve_single_input.(input, info) end)
      end
    }
  end
end
