defmodule EpiContacts.UtilsTest do
  use ExUnit.Case, async: true

  alias EpiContacts.Utils

  describe "collect_first_elements/1" do
    test "returns an empty list when given an empty list" do
      assert Utils.collect_first_elements([]) == []
    end
    test "returns list of first elements of sub-collections" do
      list = [{"a", 1}, {"b", 2}]
      assert Utils.collect_first_elements(list) == ["a", "b"]
    end
  end
end
