defmodule GraphQL.Relay.Connection.ListTest do
  use ExUnit.Case, async: true

  alias GraphQL.Relay.Connection

  def letters do
    ["A", "B", "C", "D", "E"]
  end

  test "basic slicing: returns all elements without filters" do
    expected = %{
      edges: [
        %{
          node: "A",
          cursor: "YXJyYXljb25uZWN0aW9uOjA=",
        },
        %{
          node: "B",
          cursor: "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
        %{
          node: "D",
          cursor: "YXJyYXljb25uZWN0aW9uOjM=",
        },
        %{
          node: "E",
          cursor: "YXJyYXljb25uZWN0aW9uOjQ=",
        }
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjA=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjQ=",
        hasPreviousPage: false,
        hasNextPage: false
      }
    }
    assert(Connection.List.resolve(letters) == expected)
  end

  test "respects a smaller first" do
    expected = %{
      edges: [
        %{ node: "A",
          cursor: "YXJyYXljb25uZWN0aW9uOjA=",
        },
        %{
          node: "B",
          cursor: "YXJyYXljb25uZWN0aW9uOjE=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjA=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjE=",
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    assert(Connection.List.resolve(letters, %{first: 2}) == expected)
  end

  test "respects an overly large first" do
    expected = %{
      edges: [
        %{
          node: "A",
          cursor: "YXJyYXljb25uZWN0aW9uOjA=",
        },
        %{
          node: "B",
          cursor: "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
        %{
          node: "D",
          cursor: "YXJyYXljb25uZWN0aW9uOjM=",
        },
        %{
          node: "E",
          cursor: "YXJyYXljb25uZWN0aW9uOjQ=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjA=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjQ=",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.List.resolve(letters, %{first: 10}) == expected)
  end

  test "respects a smaller last" do
    expected = %{
      edges: [
        %{
          node: "D",
          cursor: "YXJyYXljb25uZWN0aW9uOjM=",
        },
        %{
          node: "E",
          cursor: "YXJyYXljb25uZWN0aW9uOjQ=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjM=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjQ=",
        hasPreviousPage: true,
        hasNextPage: false,
      }
    }
    assert(Connection.List.resolve(letters, %{last: 2}) == expected)
  end

  test "respects an overly large last" do
    expected = %{
      edges: [
        %{
          node: "A",
          cursor: "YXJyYXljb25uZWN0aW9uOjA=",
        },
        %{
          node: "B",
          cursor: "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
        %{
          node: "D",
          cursor: "YXJyYXljb25uZWN0aW9uOjM=",
        },
        %{
          node: "E",
          cursor: "YXJyYXljb25uZWN0aW9uOjQ=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjA=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjQ=",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.List.resolve(letters, %{last: 10}) == expected)
  end

  test "pagination: respects first and after" do
    expected = %{
      edges: [
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
        %{
          node: "D",
          cursor: "YXJyYXljb25uZWN0aW9uOjM=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjI=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjM=",
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    assert(Connection.List.resolve(letters, %{first: 2, after: "YXJyYXljb25uZWN0aW9uOjE="}) == expected)
  end

  test "respects first and after with long first" do
    expected = %{
      edges: [
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
        %{
          node: "D",
          cursor: "YXJyYXljb25uZWN0aW9uOjM=",
        },
        %{
          node: "E",
          cursor: "YXJyYXljb25uZWN0aW9uOjQ=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjI=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjQ=",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.List.resolve(letters, %{first: 10, after: "YXJyYXljb25uZWN0aW9uOjE="}) == expected)
  end

  test "respects last and before" do
    expected = %{
      edges: [
        %{
          node: "B",
          cursor: "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjE=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjI=",
        hasPreviousPage: true,
        hasNextPage: false,
      }
    }
    assert(Connection.List.resolve(letters, %{last: 2, before: "YXJyYXljb25uZWN0aW9uOjM="}) == expected)
  end

  test "respects last and before with long last" do
    expected = %{
      edges: [
        %{
          node: "A",
          cursor: "YXJyYXljb25uZWN0aW9uOjA=",
        },
        %{
          node: "B",
          cursor: "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjA=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjI=",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.List.resolve(letters, %{last: 10, before: "YXJyYXljb25uZWN0aW9uOjM="}) == expected)
  end

  test "respects first and after and before, too few" do
    expected = %{
      edges: [
        %{
          node: "B",
          cursor: "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjE=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjI=",
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    assert(Connection.List.resolve(letters, %{first: 2, "after": "YXJyYXljb25uZWN0aW9uOjA=", before: "YXJyYXljb25uZWN0aW9uOjQ="}) == expected)
  end

  test "respects first and after and before, too many" do
    expected = %{
      edges: [
        %{
          node: "B",
          cursor: "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
        %{
          node: "D",
          cursor: "YXJyYXljb25uZWN0aW9uOjM=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjE=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjM=",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.List.resolve(letters, %{first: 4, "after": "YXJyYXljb25uZWN0aW9uOjA=", before: "YXJyYXljb25uZWN0aW9uOjQ="}) == expected)
  end

  test "respects first and after and before, exactly right" do
    expected = %{
      edges: [
        %{
          node: "B",
          cursor: "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
        %{
          node: "D",
          cursor: "YXJyYXljb25uZWN0aW9uOjM=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjE=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjM=",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.List.resolve(letters, %{first: 3, "after": "YXJyYXljb25uZWN0aW9uOjA=", before: "YXJyYXljb25uZWN0aW9uOjQ="}) == expected)
  end

  test "respects last and after and before, too few" do
    expected = %{
      edges: [
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
        %{
          node: "D",
          cursor: "YXJyYXljb25uZWN0aW9uOjM=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjI=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjM=",
        hasPreviousPage: true,
        hasNextPage: false,
      }
    }
    assert(Connection.List.resolve(letters, %{last: 2, "after": "YXJyYXljb25uZWN0aW9uOjA=", before: "YXJyYXljb25uZWN0aW9uOjQ="}) == expected)
  end

  test "respects last and after and before, too many" do
    expected = %{
      edges: [
        %{
          node: "B",
          cursor: "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
        %{
          node: "D",
          cursor: "YXJyYXljb25uZWN0aW9uOjM=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjE=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjM=",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.List.resolve(letters, %{last: 4, "after": "YXJyYXljb25uZWN0aW9uOjA=", before: "YXJyYXljb25uZWN0aW9uOjQ="}) == expected)
  end

  test "respects last and after and before, exactly right" do
    expected = %{
      edges: [
        %{
          node: "B",
          cursor: "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
        %{
          node: "D",
          cursor: "YXJyYXljb25uZWN0aW9uOjM=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjE=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjM=",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.List.resolve(letters, %{last: 3, "after": "YXJyYXljb25uZWN0aW9uOjA=", before: "YXJyYXljb25uZWN0aW9uOjQ="}) == expected)
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
    assert(Connection.List.resolve(letters, %{first: 0}) == expected)
  end

  test "returns all elements if cursors are invalid" do
    expected = %{
      edges: [
        %{
          node: "A",
          cursor: "YXJyYXljb25uZWN0aW9uOjA=",
        },
        %{
          node: "B",
          cursor: "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
        %{
          node: "D",
          cursor: "YXJyYXljb25uZWN0aW9uOjM=",
        },
        %{
          node: "E",
          cursor: "YXJyYXljb25uZWN0aW9uOjQ=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjA=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjQ=",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.List.resolve(letters, %{before: "invalid", after: "invalid"}) == expected)
  end

  test "returns all elements if cursors are on the outside" do
    expected = %{
      edges: [
        %{
          node: "A",
          cursor: "YXJyYXljb25uZWN0aW9uOjA=",
        },
        %{
          node: "B",
          cursor: "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
        %{
          node: "D",
          cursor: "YXJyYXljb25uZWN0aW9uOjM=",
        },
        %{
          node: "E",
          cursor: "YXJyYXljb25uZWN0aW9uOjQ=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjA=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjQ=",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(Connection.List.resolve(letters, %{before: "YXJyYXljb25uZWN0aW9uOjYK", "after": "YXJyYXljb25uZWN0aW9uOi0xCg=="}) == expected)
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
    assert(Connection.List.resolve(letters, %{before: "YXJyYXljb25uZWN0aW9uOjI=", "after": "YXJyYXljb25uZWN0aW9uOjQ="}) == expected)
  end

  test "cursor_for_object_in_connection: returns an edge\"s cursor, given an array and a member object" do
    letter_b_cursor = Connection.List.cursor_for_object_in_connection(letters, "B")
    assert(letter_b_cursor == "YXJyYXljb25uZWN0aW9uOjE=")
  end

  test "returns nil, given an array and a non-member object" do
    letter_f_cursor = Connection.List.cursor_for_object_in_connection(letters, "F")
    assert(letter_f_cursor == nil)
  end

  test "resolve_slice: works with a just-right array slice" do
    expected = %{
      edges: [
        %{
          node: "B",
          cursor: "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjE=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjI=",
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    assert(
      Connection.List.resolve_slice(
        Enum.slice(letters, 1..2),
        %{
          first: 2,
          "after": "YXJyYXljb25uZWN0aW9uOjA=",
        },
        %{
          slice_start: 1,
          list_length: 5,
        }
      ) == expected)
  end

  test "works with an oversized array slice ('left' side)" do
    expected = %{
      edges: [
        %{
          node: "B",
          cursor: "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjE=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjI=",
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    assert(
      Connection.List.resolve_slice(
        Enum.slice(letters, 0..2),
        %{
          first: 2,
          "after": "YXJyYXljb25uZWN0aW9uOjA=",
        },
        %{
          slice_start: 0,
          list_length: 5,
        }
      ) == expected)
  end

  test "works with an oversized array slice ('right' side)" do
    expected = %{
      edges: [
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjI=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjI=",
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    assert(
      Connection.List.resolve_slice(
        Enum.slice(letters, 2..3),
        %{
          first: 1,
          "after": "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          slice_start: 2,
          list_length: 5,
        }
      ) == expected)
  end

  test "works with an oversized array slice (both sides)" do
    expected = %{
      edges: [
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjI=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjI=",
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    assert(
      Connection.List.resolve_slice(
        Enum.slice(letters, 1..3),
        %{
          first: 1,
          "after": "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          slice_start: 1,
          list_length: 5,
        }
      ) == expected)
  end

  test "works with an undersized array slice ('left' side)" do
    expected = %{
      edges: [
        %{
          node: "D",
          cursor: "YXJyYXljb25uZWN0aW9uOjM=",
        },
        %{
          node: "E",
          cursor: "YXJyYXljb25uZWN0aW9uOjQ=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjM=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjQ=",
        hasPreviousPage: false,
        hasNextPage: false,
      }
    }
    assert(
      Connection.List.resolve_slice(
        Enum.slice(letters, 3..4),
        %{
          first: 3,
          "after": "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          slice_start: 3,
          list_length: 5,
        }
      ) == expected)
  end

  test "works with an undersized array slice ('right' side)" do
    expected = %{
      edges: [
        %{
          node: "C",
          cursor: "YXJyYXljb25uZWN0aW9uOjI=",
        },
        %{
          node: "D",
          cursor: "YXJyYXljb25uZWN0aW9uOjM=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjI=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjM=",
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    assert(
      Connection.List.resolve_slice(
        Enum.slice(letters, 2..3),
        %{
          first: 3,
          "after": "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          slice_start: 2,
          list_length: 5,
        }
      ) == expected)
  end

  test "works with an undersized array slice (both sides)" do
    expected = %{
      edges: [
        %{
          node: "D",
          cursor: "YXJyYXljb25uZWN0aW9uOjM=",
        },
      ],
      pageInfo: %{
        startCursor: "YXJyYXljb25uZWN0aW9uOjM=",
        endCursor: "YXJyYXljb25uZWN0aW9uOjM=",
        hasPreviousPage: false,
        hasNextPage: true,
      }
    }
    assert(
      Connection.List.resolve_slice(
        Enum.slice(letters, 3..3),
        %{
          first: 3,
          after: "YXJyYXljb25uZWN0aW9uOjE=",
        },
        %{
          slice_start: 3,
          list_length: 5,
        }
      ) == expected)
  end
end
