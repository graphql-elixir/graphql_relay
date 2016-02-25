Code.require_file "../support/star_wars/data.exs", __DIR__
Code.require_file "../support/star_wars/schema.exs", __DIR__
# Code.require_file "../support/star_wars/schema_without_library.exs", __DIR__

defmodule GraphQL.StarWars.MutationTest do
  use ExUnit.Case
  import ExUnit.TestHelpers

  test "mutates the data set" do
    mutation = """
      mutation AddBWingQuery($input: IntroduceShipInput!) {
        introduceShip(input: $input) {
          ship {
            id
            name
          }
          faction {
            name
          }
          clientMutationId
        }
      }
    """
    params = %{
      input: %{
        clientMutationId: "abcde",
        factionId: "1",
        shipName: "B-Wing",
      }
    }
    expected = %{
      introduceShip: %{
        ship: %{
          id: "c2hpcDo5",
          name: "B-Wing"
        },
        faction: %{
          name: "Alliance to Restore the Republic"
        },
        clientMutationId: "abcde",
      }
    }
    assert_execute({mutation, StarWars.Schema.schema, nil, params}, expected)
  end
end
