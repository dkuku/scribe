defmodule Scribe.TableTest do
  use ExUnit.Case

  test "format/3 returns formatted table string" do
    data = [
      ["test", 1234, "longer string to check"],
      [0, nil, :whatever],
      [0.000001, 1_000_000, 0x123456],
      [{:ok, 2}, [true, false], {:error, :we, :failed}]
    ]

    expected = """
    +------+------+------------------------+
    | test | 1234 | longer string to check |
    +------+------+------------------------+
    | 0    | nil  | :whatever              |
    | 1.0e | 1000 | 1193046                |
    | {:ok | [tru | {:error, :we, :failed} |
    +------+------+------------------------+
    """

    assert Scribe.Table.format(data, 2, 3, colorize: false) == expected
  end

  test "format/3 returns formatted table string with inspect" do
    data = [
      ["test", 1234, "longer string to check"],
      [0, nil, :whatever],
      [0.000001, 1_000_000, 0x123456],
      [{:ok, 2}, [1, 2], {:error, :we, :failed}]
    ]

    expected = """
    +--------+------+--------------------------+
    | \"test\" | 1234 | \"longer string to check\" |
    +--------+------+--------------------------+
    | 0      | nil  | :whatever                |
    | 1.0e-6 | 1000 | 1193046                  |
    | {:ok,  | [1,  | {:error, :we, :failed}   |
    +--------+------+--------------------------+
    """

    assert Scribe.Table.format(data, 2, 3, colorize: false, inspect: true) ==
             expected
  end
end
