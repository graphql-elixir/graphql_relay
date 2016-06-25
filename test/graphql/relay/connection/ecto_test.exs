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
    # Ecto v1.x
    # Repo.insert(%Letter{letter: "a"})
    # Repo.insert(%Letter{letter: "b"})
    # Repo.insert(%Letter{letter: "c"})
    # Repo.insert(%Letter{letter: "d"})
    # Repo.insert(%Letter{letter: "e"})
    # Ecto.Adapters.SQL.begin_test_transaction(Repo)

    :ok
  end

  setup do
    # Ecto v1.x
    # Ecto.Adapters.SQL.restart_test_transaction(Repo, [])

    # Ecto v2.x

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    a = Repo.insert!(%Letter{letter: "a", order: 100})
    b = Repo.insert!(%Letter{letter: "b", order: 101})
    c = Repo.insert!(%Letter{letter: "c", order: 102})
    d = Repo.insert!(%Letter{letter: "d", order: 103})
    Repo.insert(%Letter{letter: "e", order: 104})

    Repo.insert!(%Number{number: 1, letter_id: a.id})
    Repo.insert!(%Number{number: 2, letter_id: b.id})
    Repo.insert!(%Number{number: 3, letter_id: c.id})
    Repo.insert!(%Number{number: 4, letter_id: d.id})
    :ok
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

  defp edge_for_object(obj), do: edge_for_object(obj, :id)
  defp edge_for_object(obj, ordered_by) do
    %{
      node: obj,
      cursor: Base.encode64("ectoconnection:#{Map.get(obj, ordered_by)}")
    }
  end

  test "querying for counts does not raise exception if select already exists" do
    query = letters_query
      |> select([l], %{id: l.id, letter: l.letter})
      |> order_by([l], asc: l.second_column)
    assert(Connection.Ecto.resolve(Repo, query))
  end

  test "preloading does not raise an exception if select already exists" do
    query = letters_query
    |> join(:inner, [l], n in assoc(l, :number))
    |> preload(:number)
    assert(Connection.Ecto.resolve(Repo, query))
  end

  test "basic slicing: returns all elements without filters" do
    expected = %{
      edges: [
        edge_for_object(a),
        edge_for_object(b),
        edge_for_object(c),
        edge_for_object(d),
        edge_for_object(e),
      ],
      pageInfo: %{
        startCursor: edge_for_object(a).cursor,
        endCursor: edge_for_object(e).cursor,
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    result = Connection.Ecto.resolve(Repo, letters_query)
    assert(result == expected)
  end

  test "respects a smaller first" do
    expected = %{
      edges: [
        edge_for_object(a),
        edge_for_object(b),
      ],
      pageInfo: %{
        startCursor: edge_for_object(a).cursor,
        endCursor: edge_for_object(b).cursor,
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    result = Connection.Ecto.resolve(Repo, letters_query, %{first: 2})
    assert(result == expected)
  end

  test "respects an overly large first" do
    expected = %{
      edges: [
        edge_for_object(a),
        edge_for_object(b),
        edge_for_object(c),
        edge_for_object(d),
        edge_for_object(e),
      ],
      pageInfo: %{
        startCursor: edge_for_object(a).cursor,
        endCursor: edge_for_object(e).cursor,
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(Repo, letters_query, %{first: 10}) == expected)
  end

  test "respects a smaller last" do
    expected = %{
      edges: [
        edge_for_object(d),
        edge_for_object(e),
      ],
      pageInfo: %{
        startCursor: edge_for_object(d).cursor,
        endCursor: edge_for_object(e).cursor,
        hasPreviousPage: true,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(Repo, letters_query, %{last: 2}) == expected)
  end

  test "respects an overly large last" do
    expected = %{
      edges: [
        edge_for_object(a),
        edge_for_object(b),
        edge_for_object(c),
        edge_for_object(d),
        edge_for_object(e),
      ],
      pageInfo: %{
        startCursor: edge_for_object(a).cursor,
        endCursor: edge_for_object(e).cursor,
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(Repo, letters_query, %{last: 10}) == expected)
  end

  test "pagination: respects first and after" do
    expected = %{
      edges: [
        edge_for_object(c),
        edge_for_object(d),
      ],
      pageInfo: %{
        startCursor: edge_for_object(c).cursor,
        endCursor: edge_for_object(d).cursor,
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    assert(Connection.Ecto.resolve(Repo, letters_query, %{first: 2, after: edge_for_object(b).cursor}) == expected)
  end

  test "pagination: respects first and after with non-default ordered_by property" do
    expected = %{
      edges: [
        edge_for_object(c, :order),
        edge_for_object(d, :order),
      ],
      pageInfo: %{
        startCursor: edge_for_object(c, :order).cursor,
        endCursor: edge_for_object(d, :order).cursor,
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    assert(Connection.Ecto.resolve(Repo, letters_query, %{first: 2, after: edge_for_object(b, :order).cursor, ordered_by: :order}) == expected)
  end

  test "respects first and after with long first" do
    expected = %{
      edges: [
        edge_for_object(c),
        edge_for_object(d),
        edge_for_object(e),
      ],
      pageInfo: %{
        startCursor: edge_for_object(c).cursor,
        endCursor: edge_for_object(e).cursor,
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(Repo, letters_query, %{first: 10, after: edge_for_object(b).cursor,}) == expected)
  end

  test "respects last and before" do
    expected = %{
      edges: [
        edge_for_object(b),
        edge_for_object(c),
      ],
      pageInfo: %{
        startCursor: edge_for_object(b).cursor,
        endCursor: edge_for_object(c).cursor,
        hasPreviousPage: true,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(Repo, letters_query, %{last: 2, before: edge_for_object(d).cursor}) == expected)
  end

  test "respects last and before with long last" do
    expected = %{
      edges: [
        edge_for_object(a),
        edge_for_object(b),
        edge_for_object(c),
      ],
      pageInfo: %{
        startCursor: edge_for_object(a).cursor,
        endCursor: edge_for_object(c).cursor,
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(Repo, letters_query, %{last: 10, before: edge_for_object(d).cursor}) == expected)
  end

  test "respects first and after and before, too few" do
    expected = %{
      edges: [
        edge_for_object(b),
        edge_for_object(c),
      ],
      pageInfo: %{
        startCursor: edge_for_object(b).cursor,
        endCursor: edge_for_object(c).cursor,
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    assert(Connection.Ecto.resolve(Repo, letters_query, %{first: 2, "after": edge_for_object(a).cursor, before: edge_for_object(e).cursor}) == expected)
  end

  test "respects first and after and before, too many" do
    expected = %{
      edges: [
        edge_for_object(b),
        edge_for_object(c),
        edge_for_object(d),
      ],
      pageInfo: %{
        startCursor: edge_for_object(b).cursor,
        endCursor: edge_for_object(d).cursor,
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(Repo, letters_query, %{first: 4, "after": edge_for_object(a).cursor, before: edge_for_object(e).cursor}) == expected)
  end

  test "respects first and after and before, exactly right" do
    expected = %{
      edges: [
        edge_for_object(b),
        edge_for_object(c),
        edge_for_object(d),
      ],
      pageInfo: %{
        startCursor: edge_for_object(b).cursor,
        endCursor: edge_for_object(d).cursor,
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(Repo, letters_query, %{first: 3, "after": edge_for_object(a).cursor, before: edge_for_object(e).cursor}) == expected)
  end

  test "respects last and after and before, too few" do
    expected = %{
      edges: [
        edge_for_object(c),
        edge_for_object(d),
      ],
      pageInfo: %{
        startCursor: edge_for_object(c).cursor,
        endCursor: edge_for_object(d).cursor,
        hasPreviousPage: true,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(Repo, letters_query, %{last: 2, "after": edge_for_object(a).cursor, before: edge_for_object(e).cursor}) == expected)
  end

  test "respects last and after and before, too many" do
    expected = %{
      edges: [
        edge_for_object(b),
        edge_for_object(c),
        edge_for_object(d),
      ],
      pageInfo: %{
        startCursor: edge_for_object(b).cursor,
        endCursor: edge_for_object(d).cursor,
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(Repo, letters_query, %{last: 4, "after": edge_for_object(a).cursor, before: edge_for_object(e).cursor}) == expected)
  end

  test "respects last and after and before, exactly right" do
    expected = %{
      edges: [
        edge_for_object(b),
        edge_for_object(c),
        edge_for_object(d),
      ],
      pageInfo: %{
        startCursor: edge_for_object(b).cursor,
        endCursor: edge_for_object(d).cursor,
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(Repo, letters_query, %{last: 3, "after": edge_for_object(a).cursor, before: edge_for_object(e).cursor}) == expected)
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
    assert(Connection.Ecto.resolve(Repo, letters_query, %{first: 0}) == expected)
  end

  test "returns all elements if cursors are invalid" do
    expected = %{
      edges: [
        edge_for_object(a),
        edge_for_object(b),
        edge_for_object(c),
        edge_for_object(d),
        %{
          node: e,
          cursor: edge_for_object(e).cursor,
        },
      ],
      pageInfo: %{
        startCursor: edge_for_object(a).cursor,
        endCursor: edge_for_object(e).cursor,
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(Repo, letters_query, %{before: "invalid", after: "invalid"}) == expected)
  end

  test "returns all elements if cursors are on the outside" do
    expected = %{
      edges: [
        edge_for_object(a),
        edge_for_object(b),
        edge_for_object(c),
        edge_for_object(d),
        edge_for_object(e),
      ],
      pageInfo: %{
        startCursor: edge_for_object(a).cursor,
        endCursor: edge_for_object(e).cursor,
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.Ecto.resolve(Repo, letters_query, %{before: "ZWN0b2Nvbm5lY3Rpb246MTAwMA==", "after": "ZWN0b2Nvbm5lY3Rpb246LTE="}) == expected)
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
    assert(Connection.Ecto.resolve(Repo, letters_query, %{before: edge_for_object(c).cursor, "after": edge_for_object(e).cursor}) == expected)
  end

  test "cursor_for_object_in_connection: returns an edge's cursor" do
    letter_b_cursor = Connection.Ecto.cursor_for_object_in_connection(b)
    assert(letter_b_cursor == edge_for_object(b).cursor)
  end

  test "cursor_for_object_in_connection using a different property: returns an edge's cursor" do
    letter_b_cursor = Connection.Ecto.cursor_for_object_in_connection(b, :order)
    assert(letter_b_cursor == edge_for_object(b, :order).cursor)
  end
end
