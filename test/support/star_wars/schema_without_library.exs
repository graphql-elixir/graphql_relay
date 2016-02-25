# Based on Facebook's test schema for graphql-relay-js:
# https://github.com/graphql/graphql-relay-js
# https://facebook.github.io/relay/docs/graphql-relay-specification.html#content
#
# This particular schema is an example of setting up a Relay compliant
# schema without the use of the graphql-relay-elixir library. The
# purpose of this file is to help people understand that you don't
# need graphql-relay-elixir to setup a Relay compliant GraphQL server. It
# simply helps you to do so.
#
# I also hope this file helps people to better understand the relationship
# between GraphQL and Relay.
#
# Please see https://facebook.github.io/relay/docs/graphql-relay-specification.html#content
# for more information including the schema this file is based on.
defmodule StarWars.Schema do
  alias GraphQL.Type.Boolean
  alias GraphQL.Type.ID
  alias GraphQL.Type.Int
  alias GraphQL.Type.Interface
  alias GraphQL.Type.NonNull
  alias GraphQL.Type.ObjectType
  alias GraphQL.Schema

  def node_interface do
    %{
      name: "Node",
      description: "An object with an ID",
      fields: %{
        id: %{
          type: %NonNull{ofType: %ID{}},
          description: "The id of the object."
        }
      },
      resolver: fn(obj) ->
        case obj do
          %{ships: _ships} ->
            StarWars.Schema.faction_type
          _ ->
            StarWars.Schema.ship_type
        end
      end
    } |> Interface.new
  end

  def node_field do
    %{
      name: "node",
      description: "Fetches an object given its ID",
      type: node_interface,
      args: %{
        id: %{
          type: %NonNull{ofType: %ID{}},
          description: "The ID of an object"
        }
      },
      resolve: fn (_node, args, _ctx) ->
        {:ok, type_id} = Base.decode64(args[:id])
        [type, id] = String.split(type_id, ":")
        apply(StarWars.Data, String.downcase("get_#{type}") |> String.to_atom, [id])
      end
    }
  end

  def ship_type do
    %ObjectType{
      name: "Ship",
      description: "A ship in the Star Wars saga",
      fields: %{
        id: %{
          name: "id",
          description: "The ID of an object",
          type: %NonNull{ofType: %ID{}},
          resolve: fn (obj, _args, _info) ->
            Base.encode64("ship:#{obj.id}")
          end
        },
        name: %{
          type: %GraphQL.Type.String{},
          description: "The name of the ship.",
        }
      },
      interfaces: [node_interface]
    }
  end

  def ship_edge do
    %ObjectType{
      name: "ShipEdge",
      description: "An edge in a connection.",
      fields: %{
        node: %{
          type: ship_type,
          description: "The item at the end of the edge",
          resolve: nil
        },
        cursor: %{
          type: %NonNull{ofType: %GraphQL.Type.String{}},
          description: "A cursor for use in pagination",
          resolve: nil
        }
      }
    }
  end

  def page_info do
    %ObjectType {
      name: "PageInfo",
      fields: %{
        hasPreviousPage: %{type: %NonNull{ofType: %Boolean{}}},
        hasNextPage: %{type: %NonNull{ofType: %Boolean{}}},
        startCursor: %{type: %GraphQL.Type.String{}},
        endCursor: %{type: %GraphQL.Type.String{}}
      }
    }
  end

  def ship_connection do
    %ObjectType{
      name: "ShipConnection",
      fields: %{
        edges: %{type: %GraphQL.Type.List{ofType: ship_edge}},
        pageInfo: %{type: %NonNull{ofType: page_info}},
      }
    }
  end

  def ship_connection_args do
    %{
      first: %{
        type: %Int{}
      },
      last: %{
        type: %Int{}
      },
      before: %{
        type: %GraphQL.Type.String{}
      },
      "after": %{
        type: %GraphQL.Type.String{}
      }
    }
  end

  def faction_type do
    %ObjectType{
      name: "Faction",
      description: "A faction in the Star Wars saga",
      fields: %{
        id: %{
          name: "id",
          description: "The ID of an object",
          type: %NonNull{ofType: %ID{}},
          resolve: fn (obj, _args, _info) ->
            Base.encode64("faction:#{obj.id}")
          end
        },
        name: %{
          type: %GraphQL.Type.String{},
          description: "The name of the faction.",
        },
        ships: %{
          type: ship_connection,
          description: "The ships used by the faction.",
          args: ship_connection_args,
          resolve: &StarWars.Schema.resolve_ships/3
        }
      },
      interfaces: [node_interface]
    }
  end

  @prefix "arrayconnection:"

  def resolve_ships(faction, args, _ctx) do
    ships = Enum.map(faction.ships, fn(ship_id) -> StarWars.Data.get_ship(ship_id) end)
    before = args[:before]
    a_after = args[:after]
    first = args[:first]
    last = args[:last]
    slice_start = 0
    array_length = length(ships)
    slice_end = slice_start + length(ships)
    before_offset = get_offset_with_default(before, array_length)
    after_offset = get_offset_with_default(a_after, -1)

    start_offset = Enum.max([slice_start - 1, after_offset, -1]) + 1
    end_offset = Enum.min([slice_end, before_offset, array_length])

    if first do
      end_offset = Enum.min([end_offset, start_offset + first])
    end

    if last do
      start_offset = Enum.max([start_offset, end_offset - last])
    end

    slice = Enum.slice(ships, Enum.max([start_offset - slice_start, 0]), length(ships) - (slice_end - end_offset))

    {edges, _count} = Enum.map_reduce(slice, 0, fn(ship, acc) -> {%{ cursor: offset_to_cursor(start_offset+acc), node: ship }, acc + 1} end)

    first_edge = List.first(edges)
    last_edge = List.last(edges)
    lower_bound = a_after && after_offset + 1 || 0
    upper_bound = before && before_offset || array_length

    %{
      edges: edges,
      pageInfo: %{
        startCursor: first_edge && Map.get(first_edge, :cursor) || nil,
        endCursor: last_edge && Map.get(last_edge, :cursor) || nil,
        hasPreviousPage: last && (start_offset > lower_bound) || false,
        hasNextPage: first && (end_offset < upper_bound) || false
      }
    }
  end

  def get_offset_with_default(cursor, default_offset) do
    unless cursor do
      default_offset
    else
      offset = cursor_to_offset(cursor)
      offset || default_offset
    end
  end

  def cursor_to_offset(cursor) do
    case Base.decode64(cursor) do
      {:ok, decoded_cursor} ->
        {int, _} = Integer.parse(String.slice(decoded_cursor, String.length(@prefix)..String.length(decoded_cursor)))
        int
      :error ->
        nil
    end
  end

  def offset_to_cursor(offset) do
    Base.encode64("#{@prefix}#{offset}")
  end

  def query do
    %ObjectType{
      name: "Query",
      fields: %{
        rebels: %{
          type: faction_type,
          resolve: fn(_obj, _args, _ctx) -> StarWars.Data.get_rebels end,
        },
        empire: %{
          type: faction_type,
          resolve: fn(_obj, _args, _ctx) -> StarWars.Data.get_empire end,
        },
        node: node_field
      }
    }
  end

  def ship_mutation do
    %{
      name: "IntroduceShip",
      description: "Assign a new Ship to a Faction",
      type: %ObjectType{
        name: "IntroduceShipPayload",
        fields: %{
          clientMutationId: %{type: %NonNull{ofType: %GraphQL.Type.String{}}},
          ship: %{
            type: ship_type,
            resolve: fn(payload, _, _) -> StarWars.Data.get_ship(payload[:shipId]) end
          },
          faction: %{
            type: faction_type,
            resolve: fn(payload, _, _) -> StarWars.Data.get_faction(payload[:factionId]) end
          }
        }
      },
      args: %{
        input: %{
          type: %NonNull{ofType: %ObjectType{
              name: "IntroduceShipInput",
              fields: %{
                clientMutationId: %{type: %NonNull{ofType: %GraphQL.Type.String{}}},
                factionId: %{type: %NonNull{ofType: %ID{}}},
                shipName: %{type: %NonNull{ofType: %GraphQL.Type.String{}}},
              }
            }
          }
        }
      },
      resolve: fn(_item, args, _info) ->
        input = args[:input]
        new_ship = StarWars.Data.create_ship(input[:shipName], input[:factionId])
        %{
          shipId: new_ship.id,
          factionId: input[:factionId],
          clientMutationId: input[:clientMutationId]
        }
      end
    }
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
