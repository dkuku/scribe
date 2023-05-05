defmodule Scribe.ScribeTest do
  defstruct id: nil, value: 1234
  defdelegate fetch(term, key), to: Map
  defdelegate get(term, key, default), to: Map
  defdelegate get_and_update(term, key, fun), to: Map

  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  describe "format/2" do
    test "minimal example" do
      t = %Scribe.ScribeTest{}

      expected = """
      +-------------------+-----+--------+
      | STRUCT            | :id | :value |
      +-------------------+-----+--------+
      | Scribe.ScribeTest | nil | 1234   |
      | Scribe.ScribeTest | nil | 1234   |
      +-------------------+-----+--------+
      """

      actual = Scribe.format([t, t], colorize: false)
      assert actual == expected
    end

    test "minimal example transposed" do
      data = %{id: [1,2,3], type: [:a, :b, :c]}

      expected = """
      +-----+-------+
      | :id | :type |
      +-----+-------+
      | 1   | :a    |
      | 2   | :b    |
      | 3   | :c    |
      +-----+-------+
      """

      actual = Scribe.format(data, colorize: false)
      assert actual == expected
    end

    test "includes __struct__ attributes" do
      t = %Scribe.ScribeTest{}

      expected = """
      +-------------------+-----+--------+
      | STRUCT            | :id | :value |
      +-------------------+-----+--------+
      | Scribe.ScribeTest | nil | 1234   |
      +-------------------+-----+--------+
      """

      actual = Scribe.format([t], colorize: false)
      assert actual == expected
    end

    test "formats multiple rows of data" do
      t = %Scribe.ScribeTest{}

      expected = """
      +-------------------+-----+--------+
      | STRUCT            | :id | :value |
      +-------------------+-----+--------+
      | Scribe.ScribeTest | nil | 1234   |
      | Scribe.ScribeTest | nil | 1234   |
      | Scribe.ScribeTest | nil | 1234   |
      +-------------------+-----+--------+
      """

      actual = Scribe.format([t, t, t], colorize: false)
      assert actual == expected
    end

    test "maps as data source" do
      t = %{test: 1234, key: "testing"}

      expected = """
      +---------+-------+
      | :key    | :test |
      +---------+-------+
      | testing | 1234  |
      +---------+-------+
      """

      actual = Scribe.format([t], colorize: false)
      assert actual == expected
    end

    test "keyword as data source" do
      t = [key: "testing", test: 1234]

      expected = """
      +---------+-------+
      | :key    | :test |
      +---------+-------+
      | testing | 1234  |
      +---------+-------+
      """

      actual = Scribe.format([t], colorize: false)
      assert actual == expected
    end

    test "displays only specified keys" do
      t = %{test: 1234, key: "testing"}

      expected = """
      +---------+
      | :key    |
      +---------+
      | testing |
      +---------+
      """

      actual = Scribe.format([t], data: [:key], colorize: false)
      assert actual == expected
    end

    test "displays specified keys with given titles" do
      t = %{test: 1234, key: "testing"}

      expected = """
      +---------+
      | :title  |
      +---------+
      | testing |
      +---------+
      """

      actual = Scribe.format([t], data: [title: :key], colorize: false)
      assert actual == expected
    end

    test "displays specified keys with given titles, some untitled" do
      t = %{test: 1234, key: "testing"}

      expected = """
      +---------+-------+
      | :title  | :test |
      +---------+-------+
      | testing | 1234  |
      +---------+-------+
      """

      actual =
        Scribe.format(
          [t],
          data: [{:title, :key}, :test],
          colorize: false
        )

      assert actual == expected
    end

    test "does function with given title" do
      t = %{test: 1234, key: "testing"}

      expected = """
      +---------+
      | Caps    |
      +---------+
      | TESTING |
      +---------+
      """

      actual =
        Scribe.format(
          [t],
          data: [{"Caps", fn x -> String.upcase(x.key) end}],
          colorize: false
        )

      assert actual == expected
    end

    test "respects width option" do
      t = %{test: 1234, key: "testing"}

      expected = """
      +-----------------------+-------------------+
      | :title                | :test             |
      +-----------------------+-------------------+
      | testing               | 1234              |
      +-----------------------+-------------------+
      """

      actual =
        Scribe.format(
          [t],
          data: [{:title, :key}, :test],
          colorize: false,
          width: 50
        )

      assert actual == expected
    end
  end

  describe "print/2" do
    test "outputs proper IO" do
      fun = fn -> Scribe.print([%{test: 1234}]) end

      exp = """
      \e[39m+-------+
      |\e[36m :test \e[0m|
      +-------+
      |\e[33m 1234  \e[0m|
      +-------+

      """

      assert capture_io(fun) == exp
    end

    test "outputs proper IO with opts" do
      fun = fn -> Scribe.print([%{test: 1234}], colorize: false) end

      exp = "+-------+\n| :test |\n+-------+\n| 1234  |\n+-------+\n\n"

      assert capture_io(fun) == exp
    end
  end
end
