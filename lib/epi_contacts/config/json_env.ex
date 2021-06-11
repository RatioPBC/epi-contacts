defmodule EpiContacts.Config.JsonEnv do
  @moduledoc false
  defstruct variable: "", bindings: []

  defimpl Vapor.Provider do
    def load(%{variable: variable, bindings: bindings}) do
      json_string = System.get_env(variable)

      if json_string do
        json = Jason.decode!(json_string)

        bound_envs =
          bindings
          |> Enum.map(&create_binding(&1, json))
          |> Enum.reject(fn {_, val} -> val == :missing end)
          |> Enum.into(%{})

        {:ok, bound_envs}
      else
        {:ok, %{}}
      end
    end

    defp create_binding({name, key}, json) do
      if val = json[key] do
        {name, val}
      else
        {name, :missing}
      end
    end
  end
end
