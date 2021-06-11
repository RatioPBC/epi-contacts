defmodule EpiContacts.Extra.MapTest do
  use ExUnit.Case, async: true

  alias EpiContacts.Extra

  describe "atomize_keys" do
    test "converts string keys to atom keys within a map" do
      map = %{
        "keyA" => "valueA",
        "keyB" => "valueB"
      }

      assert Extra.Map.atomize_keys(map) == %{
               keyA: "valueA",
               keyB: "valueB"
             }
    end

    test "atomizes a map with non-string keys safely" do
      map = %{
        "keyA" => "valueA",
        2 => "value2"
      }

      assert Extra.Map.atomize_keys(map) == %{
               :keyA => "valueA",
               2 => "value2"
             }
    end

    test "works recursively" do
      map = %{
        "keyA1" => "valueA1",
        "keyA2" => %{
          "keyB1" => "valueB1",
          "keyB2" => "valueB2",
          "keyB3" => %{
            "keyC1" => "valueC1",
            "keyC2" => "valueC2",
            "keyC3" => "valueC3"
          }
        }
      }

      assert Extra.Map.atomize_keys(map) == %{
               keyA1: "valueA1",
               keyA2: %{
                 keyB1: "valueB1",
                 keyB2: "valueB2",
                 keyB3: %{
                   keyC1: "valueC1",
                   keyC2: "valueC2",
                   keyC3: "valueC3"
                 }
               }
             }
    end
  end
end
