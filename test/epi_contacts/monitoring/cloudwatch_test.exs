defmodule EpiContacts.Monitoring.CloudwatchTest do
  use ExUnit.Case, async: true

  alias EpiContacts.Monitoring.Cloudwatch

  describe "to_metric_data" do
    setup context do
      value = Application.get_env(:epi_contacts, :environment_name)

      if name = context[:environment_name] do
        Application.put_env(:epi_contacts, :environment_name, name)

        on_exit(fn ->
          Application.put_env(:epi_contacts, :environment_name, value)
        end)
      end

      :ok
    end

    test "maps values to cloudwatch metric data" do
      result =
        %{
          "i.did.stuff" => 12,
          "and.some.things" => 9000
        }
        |> Cloudwatch.to_metric_data(type: "awesome")

      assert(
        result == [
          [metric_name: "and.some.things", value: 9000, dimensions: [{"Environment", :test}, {"Type", "awesome"}]],
          [metric_name: "i.did.stuff", value: 12, dimensions: [{"Environment", :test}, {"Type", "awesome"}]]
        ]
      )
    end

    @tag environment_name: :stuff
    test "uses config for Environment", context do
      result =
        %{"yo" => 12}
        |> Cloudwatch.to_metric_data(type: "things")

      assert(
        result == [
          [metric_name: "yo", value: 12, dimensions: [{"Environment", context.environment_name}, {"Type", "things"}]]
        ]
      )
    end

    test "merges passed dimensions" do
      result =
        %{
          "i.did.stuff" => 12,
          "and.some.things" => 9000
        }
        |> Cloudwatch.to_metric_data(type: "awesome", dimensions: [{"Domain", "ny-essex"}])

      assert(
        result == [
          [
            metric_name: "and.some.things",
            value: 9000,
            dimensions: [{"Domain", "ny-essex"}, {"Environment", :test}, {"Type", "awesome"}]
          ],
          [
            metric_name: "i.did.stuff",
            value: 12,
            dimensions: [{"Domain", "ny-essex"}, {"Environment", :test}, {"Type", "awesome"}]
          ]
        ]
      )
    end
  end
end
