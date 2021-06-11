defmodule EpiContacts.ApplicationTest do
  use ExUnit.Case, async: false

  describe "merge_env" do
    setup do
      Application.put_env(:share_my_contacts, :test_key,
        queues: [default: 10],
        url: [host: "localhost"]
      )

      on_exit(fn ->
        Application.delete_env(:share_my_contacts, :test_key)
      end)
    end

    test "merges in new application settings" do
      new_keys = [url: [host: "new"], color: :red]
      EpiContacts.Application.merge_env(:share_my_contacts, :test_key, new_keys)
      new_env = Application.get_env(:share_my_contacts, :test_key)
      assert new_env == [{:queues, [default: 10]}, {:url, [host: "new"]}, {:color, :red}]
    end
  end
end
