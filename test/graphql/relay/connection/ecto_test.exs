defmodule GraphQL.Relay.Connection.EctoTest do
  use ExUnit.Case, async: true

  import Ecto.Query

  alias GraphQL.Relay.Connection
  alias EctoTest.Repo

  defmodule Letter do
    use Ecto.Schema

    schema "letters" do
      field :letter, :string
      field :second_column, :string
      timestamps
    end
  end

  setup_all do
    Repo.insert(%Letter{letter: a})
    Repo.insert(%Letter{letter: b})
    Repo.insert(%Letter{letter: c})
    Repo.insert(%Letter{letter: d})
    Repo.insert(%Letter{letter: e})

    Ecto.Adapters.SQL.begin_test_transaction(Repo)

    :ok
  end

  setup do
    Ecto.Adapters.SQL.restart_test_transaction(Repo, [])
  end

  def letters do
    Repo.all(Letter)
  end

  def letters_query do
    from l in Letter
  end

  def a do
    Enum.at(letters, 0)
  end

  def b do
    Enum.at(letters, 1)
  end

  def c do
    Enum.at(letters, 2)
  end

  def d do
    Enum.at(letters, 3)
  end

  def e do
    Enum.at(letters, 4)
  end

  test "querying for counts does not raise exception if select already exists" do
    query = letters_query
      |> select([l], %{id: l.id, letter: l.letter})
      |> order_by([l], asc: l.second_column)
    assert(Connection.Ecto.resolve(query, %{repo: Repo}))
  end

  test "basic slicing: returns all elements without filters" do
    expected = %{
      edges: [
        %{
          node: a,
          cursor: "ZWN0b2Nvbm5lY3Rpb246MQ==",
        },
        %{
          node: b,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        },
        %{
          node: c,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        },
        %{
          node: d,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        },
        %{
          node: e,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NQ==",
        }
      ],
      pageInfo: %{
        startCursor: "ZWN0b2Nvbm5lY3Rpb246MQ==",
        endCursor: "ZWN0b2Nvbm5lY3Rpb246NQ==",
        hasPreviousPage: false,
        hasNextPage: false
      }
    }
    result = Connection.Ecto.resolve(letters_query, %{repo: Repo})
    assert(result == expected)
  end

  test "respects a smaller first" do
    expected = %{
      edges: [
        %{ node: a,
          cursor: "ZWN0b2Nvbm5lY3Rpb246MQ==",
        },
        %{
          node: b,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        },
      ],
      pageInfo: %{
        startCursor: "ZWN0b2Nvbm5lY3Rpb246MQ==",
        endCursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    result = Connection.Ecto.resolve(letters_query, %{repo: Repo, first: 2})
    assert(result == expected)
  end

  test "respects an overly large first" do
    expected = %{
      edges: [
        %{
          node: a,
          cursor: "ZWN0b2Nvbm5lY3Rpb246MQ==",
        },
        %{
          node: b,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        },
        %{
          node: c,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        },
        %{
          node: d,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        },
        %{
          node: e,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NQ==",
        },
      ],
      pageInfo: %{
        startCursor: "ZWN0b2Nvbm5lY3Rpb246MQ==",
        endCursor: "ZWN0b2Nvbm5lY3Rpb246NQ==",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, first: 10}) == expected)
  end

  test "respects a smaller last" do
    expected = %{
      edges: [
        %{
          node: d,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        },
        %{
          node: e,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NQ==",
        },
      ],
      pageInfo: %{
        startCursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        endCursor: "ZWN0b2Nvbm5lY3Rpb246NQ==",
        hasPreviousPage: true,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, last: 2}) == expected)
  end

  test "respects an overly large last" do
    expected = %{
      edges: [
        %{
          node: a,
          cursor: "ZWN0b2Nvbm5lY3Rpb246MQ==",
        },
        %{
          node: b,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        },
        %{
          node: c,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        },
        %{
          node: d,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        },
        %{
          node: e,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NQ==",
        },
      ],
      pageInfo: %{
        startCursor: "ZWN0b2Nvbm5lY3Rpb246MQ==",
        endCursor: "ZWN0b2Nvbm5lY3Rpb246NQ==",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, last: 10}) == expected)
  end

  test "pagination: respects first and after" do
    expected = %{
      edges: [
        %{
          node: c,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        },
        %{
          node: d,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        },
      ],
      pageInfo: %{
        startCursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        endCursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, first: 2, after: "ZWN0b2Nvbm5lY3Rpb246Mg=="}) == expected)
  end

  test "respects first and after with long first" do
    expected = %{
      edges: [
        %{
          node: c,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        },
        %{
          node: d,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        },
        %{
          node: e,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NQ==",
        },
      ],
      pageInfo: %{
        startCursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        endCursor: "ZWN0b2Nvbm5lY3Rpb246NQ==",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, first: 10, after: "ZWN0b2Nvbm5lY3Rpb246Mg=="}) == expected)
  end

  test "respects last and before" do
    expected = %{
      edges: [
        %{
          node: b,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        },
        %{
          node: c,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        },
      ],
      pageInfo: %{
        startCursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        endCursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        hasPreviousPage: true,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, last: 2, before: "ZWN0b2Nvbm5lY3Rpb246NA=="}) == expected)
  end

  test "respects last and before with long last" do
    expected = %{
      edges: [
        %{
          node: a,
          cursor: "ZWN0b2Nvbm5lY3Rpb246MQ==",
        },
        %{
          node: b,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        },
        %{
          node: c,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        },
      ],
      pageInfo: %{
        startCursor: "ZWN0b2Nvbm5lY3Rpb246MQ==",
        endCursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, last: 10, before: "ZWN0b2Nvbm5lY3Rpb246NA=="}) == expected)
  end

  test "respects first and after and before, too few" do
    expected = %{
      edges: [
        %{
          node: b,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        },
        %{
          node: c,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        },
      ],
      pageInfo: %{
        startCursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        endCursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, first: 2, "after": "ZWN0b2Nvbm5lY3Rpb246MQ==", before: "ZWN0b2Nvbm5lY3Rpb246NQ=="}) == expected)
  end

  test "respects first and after and before, too many" do
    expected = %{
      edges: [
        %{
          node: b,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        },
        %{
          node: c,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        },
        %{
          node: d,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        },
      ],
      pageInfo: %{
        startCursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        endCursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, first: 4, "after": "ZWN0b2Nvbm5lY3Rpb246MQ==", before: "ZWN0b2Nvbm5lY3Rpb246NQ=="}) == expected)
  end

  test "respects first and after and before, exactly right" do
    expected = %{
      edges: [
        %{
          node: b,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        },
        %{
          node: c,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        },
        %{
          node: d,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        },
      ],
      pageInfo: %{
        startCursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        endCursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, first: 3, "after": "ZWN0b2Nvbm5lY3Rpb246MQ==", before: "ZWN0b2Nvbm5lY3Rpb246NQ=="}) == expected)
  end

  test "respects last and after and before, too few" do
    expected = %{
      edges: [
        %{
          node: c,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        },
        %{
          node: d,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        },
      ],
      pageInfo: %{
        startCursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        endCursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        hasPreviousPage: true,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, last: 2, "after": "ZWN0b2Nvbm5lY3Rpb246MQ==", before: "ZWN0b2Nvbm5lY3Rpb246NQ=="}) == expected)
  end

  test "respects last and after and before, too many" do
    expected = %{
      edges: [
        %{
          node: b,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        },
        %{
          node: c,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        },
        %{
          node: d,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        },
      ],
      pageInfo: %{
        startCursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        endCursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, last: 4, "after": "ZWN0b2Nvbm5lY3Rpb246MQ==", before: "ZWN0b2Nvbm5lY3Rpb246NQ=="}) == expected)
  end

  test "respects last and after and before, exactly right" do
    expected = %{
      edges: [
        %{
          node: b,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        },
        %{
          node: c,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        },
        %{
          node: d,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        },
      ],
      pageInfo: %{
        startCursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        endCursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, last: 3, "after": "ZWN0b2Nvbm5lY3Rpb246MQ==", before: "ZWN0b2Nvbm5lY3Rpb246NQ=="}) == expected)
  end

  test "cursor edge cases: returns no elements if first is 0" do
    expected = %{
      edges: [],
      pageInfo: %{
        startCursor: nil,
        endCursor: nil,
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, first: 0}) == expected)
  end

  test "returns all elements if cursors are invalid" do
    expected = %{
      edges: [
        %{
          node: a,
          cursor: "ZWN0b2Nvbm5lY3Rpb246MQ==",
        },
        %{
          node: b,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        },
        %{
          node: c,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        },
        %{
          node: d,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        },
        %{
          node: e,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NQ==",
        },
      ],
      pageInfo: %{
        startCursor: "ZWN0b2Nvbm5lY3Rpb246MQ==",
        endCursor: "ZWN0b2Nvbm5lY3Rpb246NQ==",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, before: "invalid", after: "invalid"}) == expected)
  end

  test "returns all elements if cursors are on the outside" do
    expected = %{
      edges: [
        %{
          node: a,
          cursor: "ZWN0b2Nvbm5lY3Rpb246MQ==",
        },
        %{
          node: b,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mg==",
        },
        %{
          node: c,
          cursor: "ZWN0b2Nvbm5lY3Rpb246Mw==",
        },
        %{
          node: d,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NA==",
        },
        %{
          node: e,
          cursor: "ZWN0b2Nvbm5lY3Rpb246NQ==",
        },
      ],
      pageInfo: %{
        startCursor: "ZWN0b2Nvbm5lY3Rpb246MQ==",
        endCursor: "ZWN0b2Nvbm5lY3Rpb246NQ==",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, before: "ZWN0b2Nvbm5lY3Rpb246Ng==", "after": "ZWN0b2Nvbm5lY3Rpb246LTE="}) == expected)
  end

  test "returns no elements if cursors cross" do
    expected = %{
      edges: [
      ],
      pageInfo: %{
        startCursor: nil,
        endCursor: nil,
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, before: "ZWN0b2Nvbm5lY3Rpb246Mw==", "after": "ZWN0b2Nvbm5lY3Rpb246NQ=="}) == expected)
  end

  test "cursor_for_object_in_connection: returns an edge's cursor" do
    letter_b_cursor = Connection.Ecto.cursor_for_object_in_connection(b)
    assert(letter_b_cursor == "ZWN0b2Nvbm5lY3Rpb246Mg==")
  end
end
