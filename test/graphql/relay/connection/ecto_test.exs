defmodule GraphQL.Relay.Connection.EctoTest do
  use ExUnit.Case, async: true

  import Ecto.Query

  alias GraphQL.Relay.Connection
  alias EctoTest.Repo
  alias Number

  defmodule Number do
    use Ecto.Schema

    schema "numbers" do
      field :number, :integer
      field :letter_id, :integer
      # belongs_to :letter, Letter
      timestamps
    end
  end

  defmodule Letter do
    use Ecto.Schema

    schema "letters" do
      field :letter, :string
      field :second_column, :string
      field :order, :integer
      has_one :number, Number
      timestamps
    end
  end



  setup_all do
    a = Repo.insert!(%Letter{letter: "a", order: 100})
    b = Repo.insert!(%Letter{letter: "b", order: 101})
    c = Repo.insert!(%Letter{letter: "c", order: 102})
    d = Repo.insert!(%Letter{letter: "d", order: 103})
    Repo.insert(%Letter{letter: "e", order: 104})

    Repo.insert!(%Number{number: 1, letter_id: a.id})
    Repo.insert!(%Number{number: 2, letter_id: b.id})
    Repo.insert!(%Number{number: 3, letter_id: c.id})
    Repo.insert!(%Number{number: 4, letter_id: d.id})

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

  test "preloading does not raise an exception due to lack of `select`" do
    query = letters_query
    |> join(:inner, [l], n in assoc(l, :number))
    |> preload(:number)
    assert(Connection.Ecto.resolve(query, %{repo: Repo}))
  end

  @a_id_cursor "ZWN0b2Nvbm5lY3Rpb246MQ=="
  @b_id_cursor "ZWN0b2Nvbm5lY3Rpb246Mg=="
  @c_id_cursor "ZWN0b2Nvbm5lY3Rpb246Mw=="
  @d_id_cursor "ZWN0b2Nvbm5lY3Rpb246NA=="
  @e_id_cursor "ZWN0b2Nvbm5lY3Rpb246NQ=="

  @a_order_cursor "ZWN0b2Nvbm5lY3Rpb246MTAw"
  @b_order_cursor "ZWN0b2Nvbm5lY3Rpb246MTAx"
  @c_order_cursor "ZWN0b2Nvbm5lY3Rpb246MTAy"
  @d_order_cursor "ZWN0b2Nvbm5lY3Rpb246MTAz"
  @e_order_cursor "ZWN0b2Nvbm5lY3Rpb246MTA0"

  test "basic slicing: returns all elements without filters" do
    expected = %{
      edges: [
        %{
          node: a,
          cursor: @a_id_cursor,
        },
        %{
          node: b,
          cursor: @b_id_cursor,
        },
        %{
          node: c,
          cursor: @c_id_cursor,
        },
        %{
          node: d,
          cursor: @d_id_cursor,
        },
        %{
          node: e,
          cursor: @e_id_cursor,
        }
      ],
      pageInfo: %{
        startCursor: @a_id_cursor,
        endCursor: @e_id_cursor,
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
          cursor: @a_id_cursor,
        },
        %{
          node: b,
          cursor: @b_id_cursor,
        },
      ],
      pageInfo: %{
        startCursor: @a_id_cursor,
        endCursor: @b_id_cursor,
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
          cursor: @a_id_cursor,
        },
        %{
          node: b,
          cursor: @b_id_cursor,
        },
        %{
          node: c,
          cursor: @c_id_cursor,
        },
        %{
          node: d,
          cursor: @d_id_cursor,
        },
        %{
          node: e,
          cursor: @e_id_cursor,
        },
      ],
      pageInfo: %{
        startCursor: @a_id_cursor,
        endCursor: @e_id_cursor,
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
          cursor: @d_id_cursor,
        },
        %{
          node: e,
          cursor: @e_id_cursor,
        },
      ],
      pageInfo: %{
        startCursor: @d_id_cursor,
        endCursor: @e_id_cursor,
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
          cursor: @a_id_cursor,
        },
        %{
          node: b,
          cursor: @b_id_cursor,
        },
        %{
          node: c,
          cursor: @c_id_cursor,
        },
        %{
          node: d,
          cursor: @d_id_cursor,
        },
        %{
          node: e,
          cursor: @e_id_cursor,
        },
      ],
      pageInfo: %{
        startCursor: @a_id_cursor,
        endCursor: @e_id_cursor,
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
          cursor: @c_id_cursor,
        },
        %{
          node: d,
          cursor: @d_id_cursor,
        },
      ],
      pageInfo: %{
        startCursor: @c_id_cursor,
        endCursor: @d_id_cursor,
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, first: 2, after: @b_id_cursor}) == expected)
  end

  test "pagination: respects first and after with non-default where property" do
    expected = %{
      edges: [
        %{
          node: c,
          cursor: @c_order_cursor,
        },
        %{
          node: d,
          cursor: @d_order_cursor,
        },
      ],
      pageInfo: %{
        startCursor: @c_order_cursor,
        endCursor: @d_order_cursor,
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, first: 2, after: @b_order_cursor, where: :order}) == expected)
  end

  test "respects first and after with long first" do
    expected = %{
      edges: [
        %{
          node: c,
          cursor: @c_id_cursor,
        },
        %{
          node: d,
          cursor: @d_id_cursor,
        },
        %{
          node: e,
          cursor: @e_id_cursor,
        },
      ],
      pageInfo: %{
        startCursor: @c_id_cursor,
        endCursor: @e_id_cursor,
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, first: 10, after: @b_id_cursor}) == expected)
  end

  test "respects last and before" do
    expected = %{
      edges: [
        %{
          node: b,
          cursor: @b_id_cursor,
        },
        %{
          node: c,
          cursor: @c_id_cursor,
        },
      ],
      pageInfo: %{
        startCursor: @b_id_cursor,
        endCursor: @c_id_cursor,
        hasPreviousPage: true,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, last: 2, before: @d_id_cursor}) == expected)
  end

  test "respects last and before with long last" do
    expected = %{
      edges: [
        %{
          node: a,
          cursor: @a_id_cursor,
        },
        %{
          node: b,
          cursor: @b_id_cursor,
        },
        %{
          node: c,
          cursor: @c_id_cursor,
        },
      ],
      pageInfo: %{
        startCursor: @a_id_cursor,
        endCursor: @c_id_cursor,
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, last: 10, before: @d_id_cursor}) == expected)
  end

  test "respects first and after and before, too few" do
    expected = %{
      edges: [
        %{
          node: b,
          cursor: @b_id_cursor,
        },
        %{
          node: c,
          cursor: @c_id_cursor,
        },
      ],
      pageInfo: %{
        startCursor: @b_id_cursor,
        endCursor: @c_id_cursor,
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, first: 2, "after": @a_id_cursor, before: @e_id_cursor}) == expected)
  end

  test "respects first and after and before, too many" do
    expected = %{
      edges: [
        %{
          node: b,
          cursor: @b_id_cursor,
        },
        %{
          node: c,
          cursor: @c_id_cursor,
        },
        %{
          node: d,
          cursor: @d_id_cursor,
        },
      ],
      pageInfo: %{
        startCursor: @b_id_cursor,
        endCursor: @d_id_cursor,
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, first: 4, "after": @a_id_cursor, before: @e_id_cursor}) == expected)
  end

  test "respects first and after and before, exactly right" do
    expected = %{
      edges: [
        %{
          node: b,
          cursor: @b_id_cursor,
        },
        %{
          node: c,
          cursor: @c_id_cursor,
        },
        %{
          node: d,
          cursor: @d_id_cursor,
        },
      ],
      pageInfo: %{
        startCursor: @b_id_cursor,
        endCursor: @d_id_cursor,
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, first: 3, "after": @a_id_cursor, before: @e_id_cursor}) == expected)
  end

  test "respects last and after and before, too few" do
    expected = %{
      edges: [
        %{
          node: c,
          cursor: @c_id_cursor,
        },
        %{
          node: d,
          cursor: @d_id_cursor,
        },
      ],
      pageInfo: %{
        startCursor: @c_id_cursor,
        endCursor: @d_id_cursor,
        hasPreviousPage: true,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, last: 2, "after": @a_id_cursor, before: @e_id_cursor}) == expected)
  end

  test "respects last and after and before, too many" do
    expected = %{
      edges: [
        %{
          node: b,
          cursor: @b_id_cursor,
        },
        %{
          node: c,
          cursor: @c_id_cursor,
        },
        %{
          node: d,
          cursor: @d_id_cursor,
        },
      ],
      pageInfo: %{
        startCursor: @b_id_cursor,
        endCursor: @d_id_cursor,
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, last: 4, "after": @a_id_cursor, before: @e_id_cursor}) == expected)
  end

  test "respects last and after and before, exactly right" do
    expected = %{
      edges: [
        %{
          node: b,
          cursor: @b_id_cursor,
        },
        %{
          node: c,
          cursor: @c_id_cursor,
        },
        %{
          node: d,
          cursor: @d_id_cursor,
        },
      ],
      pageInfo: %{
        startCursor: @b_id_cursor,
        endCursor: @d_id_cursor,
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, last: 3, "after": @a_id_cursor, before: @e_id_cursor}) == expected)
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
          cursor: @a_id_cursor,
        },
        %{
          node: b,
          cursor: @b_id_cursor,
        },
        %{
          node: c,
          cursor: @c_id_cursor,
        },
        %{
          node: d,
          cursor: @d_id_cursor,
        },
        %{
          node: e,
          cursor: @e_id_cursor,
        },
      ],
      pageInfo: %{
        startCursor: @a_id_cursor,
        endCursor: @e_id_cursor,
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
          cursor: @a_id_cursor,
        },
        %{
          node: b,
          cursor: @b_id_cursor,
        },
        %{
          node: c,
          cursor: @c_id_cursor,
        },
        %{
          node: d,
          cursor: @d_id_cursor,
        },
        %{
          node: e,
          cursor: @e_id_cursor,
        },
      ],
      pageInfo: %{
        startCursor: @a_id_cursor,
        endCursor: @e_id_cursor,
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
    assert(Connection.Ecto.resolve(letters_query, %{repo: Repo, before: @c_id_cursor, "after": @e_id_cursor}) == expected)
  end

  test "cursor_for_object_in_connection: returns an edge's cursor" do
    letter_b_cursor = Connection.Ecto.cursor_for_object_in_connection(b)
    assert(letter_b_cursor == @b_id_cursor)
  end

  test "cursor_for_object_in_connection using a different property: returns an edge's cursor" do
    letter_b_cursor = Connection.Ecto.cursor_for_object_in_connection(b, :order)
    assert(letter_b_cursor == @b_order_cursor)
  end
end
