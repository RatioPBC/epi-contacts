defmodule EpiContacts.Config.JsonEnvTest do
  use ExUnit.Case, async: false

  alias EpiContacts.Config.JsonEnv

  @json_var_name "__TEST_JSON_ENV_VAPOR_PROVIDER__"

  describe "loading a value from an environment variable that is a JSON string" do
    setup do
      json_string = Jason.encode!(%{foo: "bar"})
      System.put_env(@json_var_name, json_string)

      on_exit(fn ->
        System.delete_env(@json_var_name)
      end)
    end

    test "given a name, valid json string, json key, it includes parsed JSON value" do
      assert Vapor.Provider.load(%JsonEnv{
               variable: @json_var_name,
               bindings: [
                 {:foo_var, "foo"}
               ]
             }) == {:ok, %{foo_var: "bar"}}
    end

    test "give a json key name that doesn't exist, it excludes it from the list of parsed variables" do
      assert Vapor.Provider.load(%JsonEnv{
               variable: @json_var_name,
               bindings: [
                 {:foo_var, "baz"}
               ]
             }) == {:ok, %{}}
    end

    test "given an invalid json variable name, it returns an empty map" do
      assert Vapor.Provider.load(%JsonEnv{
               variable: "this-is-wrong",
               bindings: [
                 {:foo_var, "foo"}
               ]
             }) == {:ok, %{}}
    end
  end
end
