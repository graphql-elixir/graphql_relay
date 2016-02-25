# Based on graphql-relay-js: https://github.com/graphql/graphql-relay-js
#
# This defines a basic set of data for our Star Wars Schema.
#
# This data is hard coded for the sake of the demo, but you could imagine
# fetching this data from a backend service rather than from hardcoded
# JSON objects in a more complex demo.
defmodule StarWars.Data do
  @xwing %{
    id: "1",
    name: "X-Wing",
  }

  @ywing %{
    id: "2",
    name: "Y-Wing",
  }

  @awing %{
    id: "3",
    name: "A-Wing",
  }

  @falcon %{
    id: "4",
    name: "Millenium Falcon",
  }

  @home_one %{
    id: "5",
    name: "Home One",
  }

  @tie_fighter %{
    id: "6",
    name: "TIE Fighter",
  }

  @tie_interceptor %{
    id: "7",
    name: "TIE Interceptor",
  }

  @executor %{
    id: "8",
    name: "Executor",
  }

  @rebels %{
    id: "1",
    name: "Alliance to Restore the Republic",
    ships: ["1", "2", "3", "4", "5"]
  }

  @empire %{
    id: "2",
    name: "Galactic Empire",
    ships: ["6", "7", "8"]
  }

  def __using__(_options) do
    populate_database
  end

  def next_ship_id do
    populate_database
    [{_, last_ship_id}] = :ets.lookup(:ships, "last_ship_id")
    :ets.delete(:ships, "last_ship_id")
    :ets.insert(:ships, {"last_ship_id", last_ship_id + 1})
    Integer.to_string(last_ship_id + 1)
  end

  def create_ship(ship_name, faction_id) do
    populate_database
    new_ship = %{
      id: next_ship_id,
      name: ship_name
    }

    :ets.insert(:ships, {new_ship[:id], new_ship})

    [{_, faction}] = :ets.lookup(:factions, faction_id)

    faction_new_ships = faction[:ships] ++ new_ship.id

    :ets.delete(:factions, faction_id)

    :ets.insert(:factions, {faction_id, %{
      faction | :ships => faction_new_ships
    }})

    new_ship
  end

  def get_ship(id) do
    populate_database
    [{_, ship}] = :ets.lookup(:ships, id)
    ship
  end

  def get_faction(id) do
    populate_database
    [{_, faction}] = :ets.lookup(:factions, id)
    faction
  end

  def get_rebels do
    get_faction("1")
  end

  def get_empire do
    get_faction("2")
  end

  def populate_database do
    if :ets.info(:ships) == :undefined do
      :ets.new(:ships, [:named_table])
      :ets.new(:factions, [:named_table])

      :ets.insert(:ships, {"1", @xwing})
      :ets.insert(:ships, {"2", @ywing})
      :ets.insert(:ships, {"3", @awing})
      :ets.insert(:ships, {"4", @falcon})
      :ets.insert(:ships, {"5", @home_one})
      :ets.insert(:ships, {"6", @tie_fighter})
      :ets.insert(:ships, {"7", @tie_interceptor})
      :ets.insert(:ships, {"8", @executor})
      :ets.insert(:ships, {"last_ship_id", 8})

      :ets.insert(:factions, {"1", @rebels})
      :ets.insert(:factions, {"2", @empire})
    end
  end
end
