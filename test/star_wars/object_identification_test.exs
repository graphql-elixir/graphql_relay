Code.require_file "../support/star_wars/data.exs", __DIR__
Code.require_file "../support/star_wars/schema.exs", __DIR__
# Code.require_file "../support/star_wars/schema_without_library.exs", __DIR__

defmodule GraphQL.StarWars.ObjectIndentificationTest do
  use ExUnit.Case, async: true
  import ExUnit.TestHelpers

  test "fetches the ID and name of the rebels" do
    query = """
      query RebelsQuery {
        rebels {
          id
          name
        }
      }
    """
    expected = %{
      rebels: %{
        id: "ZmFjdGlvbjox",
        name: "Alliance to Restore the Republic"
      }
    }
    assert_execute({query, StarWars.Schema.schema}, expected)
  end

  test "refetches the rebels" do
    query = """
      query RebelsRefetchQuery {
        node(id: "ZmFjdGlvbjox") {
          id
          ... on Faction {
            name
          }
        }
      }
    """
    expected = %{
      node: %{
        id: "ZmFjdGlvbjox",
        name: "Alliance to Restore the Republic"
      }
    }
    assert_execute({query, StarWars.Schema.schema}, expected)
  end

  test "fetches the ID and name of the empire" do
    query = """
      query EmpireQuery {
        empire {
          id
          name
        }
      }
    """
    expected = %{
      empire: %{
        id: "ZmFjdGlvbjoy",
        name: "Galactic Empire"
      }
    };
    assert_execute({query, StarWars.Schema.schema}, expected)
  end

  test "refetches the empire" do
    query = """
      query EmpireRefetchQuery {
        node(id: "RmFjdGlvbjoy") {
          id
          ... on Faction {
            name
          }
        }
      }
    """
    expected = %{
      node: %{
        id: "ZmFjdGlvbjoy",
        name: "Galactic Empire"
      }
    }
    assert_execute({query, StarWars.Schema.schema}, expected)
  end

  test "refetches the X-Wing" do
    query = """
      query XWingRefetchQuery {
        node(id: "c2hpcDox") {
          id
          ... on Ship {
            name
          }
        }
      }
    """
    expected = %{
      node: %{
        id: "c2hpcDox",
        name: "X-Wing"
      }
    }
    assert_execute({query, StarWars.Schema.schema}, expected)
  end
end
