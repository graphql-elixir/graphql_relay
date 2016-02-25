Code.require_file "../support/star_wars/data.exs", __DIR__
Code.require_file "../support/star_wars/schema.exs", __DIR__
# Code.require_file "../support/star_wars/schema_without_library.exs", __DIR__

defmodule GraphQL.StarWars.ConnectionTest do
  use ExUnit.Case, async: true
  import ExUnit.TestHelpers

  test "fetches the first ship of the rebels" do
    query = "
      query RebelsShipsQuery {
        rebels {
          name,
          ships(first: 1) {
            edges {
              node {
                name
              }
            }
          }
        }
      }
    "
    expected = %{
      rebels: %{
        name: "Alliance to Restore the Republic",
        ships: %{
          edges: [
            %{
              node: %{
                name: "X-Wing"
              }
            }
          ]
        }
      }
    }
    assert_execute({query, StarWars.Schema.schema}, expected)
  end

  test "fetches the first two ships of the rebels with a cursor" do
    query = "
      query MoreRebelShipsQuery {
        rebels {
          name,
          ships(first: 2) {
            edges {
              cursor,
              node {
                name
              }
            }
          }
        }
      }
    "
    expected = %{
      rebels: %{
        name: "Alliance to Restore the Republic",
        ships: %{
          edges: [
            %{
              cursor: "YXJyYXljb25uZWN0aW9uOjA=",
              node: %{
                name: "X-Wing"
              }
            },
            %{
              cursor: "YXJyYXljb25uZWN0aW9uOjE=",
              node: %{
                name: "Y-Wing"
              }
            }
          ]
        }
      }
    }
    assert_execute({query, StarWars.Schema.schema}, expected)
  end

  test "fetches the next three ships of the rebels with a cursor" do
    query = """
      query EndOfRebelShipsQuery {
        rebels {
          name,
          ships(first: 3 after: "YXJyYXljb25uZWN0aW9uOjE=") {
            edges {
              cursor,
              node {
                name
              }
            }
          }
        }
      }
    """
    expected = %{
      rebels: %{
        name: "Alliance to Restore the Republic",
        ships: %{
          edges: [
            %{
              cursor: "YXJyYXljb25uZWN0aW9uOjI=",
              node: %{
                name: "A-Wing"
              }
            },
            %{
              cursor: "YXJyYXljb25uZWN0aW9uOjM=",
              node: %{
                name: "Millenium Falcon"
              }
            },
            %{
              cursor: "YXJyYXljb25uZWN0aW9uOjQ=",
              node: %{
                name: "Home One"
              }
            }
          ]
        }
      }
    }
    assert_execute({query, StarWars.Schema.schema}, expected)
  end

  test "fetches no ships of the rebels at the end of connection" do
    query = """
      query RebelsQuery {
        rebels {
          name,
          ships(first: 3 after: "YXJyYXljb25uZWN0aW9uOjQ=") {
            edges {
              cursor,
              node {
                name
              }
            }
          }
        }
      }
    """
    expected = %{
      rebels: %{
        name: "Alliance to Restore the Republic",
        ships: %{
          edges: []
        }
      }
    }
    assert_execute({query, StarWars.Schema.schema}, expected)
  end

  test "identifies the end of the list" do
    query = """
      query EndOfRebelShipsQuery {
        rebels {
          name,
          originalShips: ships(first: 2) {
            edges {
              node {
                name
              }
            }
            pageInfo {
              hasNextPage
            }
          }
          moreShips: ships(first: 3 after: "YXJyYXljb25uZWN0aW9uOjE=") {
            edges {
              node {
                name
              }
            }
            pageInfo {
              hasNextPage
            }
          }
        }
      }
    """
    expected = %{
      rebels: %{
        name: "Alliance to Restore the Republic",
        originalShips: %{
          edges: [
            %{
              node: %{
                name: "X-Wing"
              }
            },
            %{
              node: %{
                name: "Y-Wing"
              }
            }
          ],
          pageInfo: %{
            hasNextPage: true
          }
        },
        moreShips: %{
          edges: [
            %{
              node: %{
                name: "A-Wing"
              }
            },
            %{
              node: %{
                name: "Millenium Falcon"
              }
            },
            %{
              node: %{
                name: "Home One"
              }
            }
          ],
          pageInfo: %{
            hasNextPage: false
          }
        }
      }
    }
    assert_execute({query, StarWars.Schema.schema}, expected)
  end
end
