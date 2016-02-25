# Based on Facebook's test schema for graphql-relay-js:
# https://github.com/graphql/graphql-relay-js
# https://facebook.github.io/relay/docs/graphql-relay-specification.html#content
defmodule StarWars.Schema do
  alias GraphQL.Schema

  alias GraphQL.Type.ID
  alias GraphQL.Type.NonNull
  alias GraphQL.Type.ObjectType

  alias GraphQL.Relay.Node
  alias GraphQL.Relay.Connection
  alias GraphQL.Relay.Mutation

  def node_interface do
    Node.define_interface(fn(obj) ->
      case obj do
        %{ships: _ships} ->
          StarWars.Schema.faction_type
        _ ->
          StarWars.Schema.ship_type
      end
    end)
  end

  def node_field do
    Node.define_field(node_interface, fn (_item, args, _ctx) ->
      [type, id] = Node.from_global_id(args[:id])
      apply(StarWars.Data,
        String.to_atom(String.downcase("get_#{type}")),
        [id]
      )
    end)
  end

  def ship_type do
    %ObjectType{
      name: "Ship",
      description: "A ship in the Star Wars saga",
      fields: %{
        id: Node.global_id_field("ship"),
        name: %{
          type: %GraphQL.Type.String{},
          description: "The name of the ship.",
        }
      },
      interfaces: [node_interface]
    }
  end

  def ship_connection do
    %{
      name: "Ship",
      node_type: ship_type,
      edge_fields: %{},
      connection_fields: %{},
      resolve_node: nil,
      resolve_cursor: nil
    } |> Connection.new
  end

  def faction_type do
    %ObjectType{
      name: "Faction",
      description: "A faction in the Star Wars saga",
      fields: %{
        id: Node.global_id_field("faction"),
        name: %{
          type: %GraphQL.Type.String{},
          description: "The name of the faction.",
        },
        ships: %{
          type: ship_connection,
          description: "The ships used by the faction.",
          args: Connection.args,
          resolve: fn(faction, args, _ctx) ->
            ships = Enum.map(faction.ships, fn(ship_id) -> StarWars.Data.get_ship(ship_id) end)
            Connection.List.resolve(ships, args)
          end
        }
      },
      interfaces: [node_interface]
    }
  end

  def query do
    %ObjectType{
      name: "Query",
      fields: %{
        rebels: %{
          type: faction_type,
          resolve: fn(_obj, _args, _ctx) -> StarWars.Data.get_rebels end
        },
        empire: %{
          type: faction_type,
          resolve: fn(_obj, _args, _ctx) -> StarWars.Data.get_empire end
        },
        node: node_field
      }
    }
  end

  def ship_mutation do
    Mutation.new(%{
      name: "IntroduceShip",
      input_fields: %{
        factionId: %{type: %NonNull{ofType: %ID{}}},
        shipName: %{type: %NonNull{ofType: %GraphQL.Type.String{}}}
      },
      output_fields: %{
        ship: %{
          type: ship_type,
          resolve: fn(payload, _, _) -> StarWars.Data.get_ship(payload[:shipId]) end
        },
        faction: %{
          type: faction_type,
          resolve: fn(payload, _, _) -> StarWars.Data.get_faction(payload[:factionId]) end
        }
      },
      mutate_and_get_payload: fn(input, _info) ->
        new_ship = StarWars.Data.create_ship(input[:shipName], input[:factionId])
        %{
          shipId: new_ship.id,
          factionId: input[:factionId]
        }
      end
    })
  end

  def mutation do
    %ObjectType{
      name: "Mutation",
      description: "Root object for performing data mutations",
      fields: %{
        introduceShip: ship_mutation
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
