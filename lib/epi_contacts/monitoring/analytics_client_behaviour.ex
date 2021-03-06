defmodule EpiContacts.Monitoring.AnalyticsClientBehaviour do
  @moduledoc """
  Provides a mockable interface around metrics reporting
  """
  @callback capture(String.t() | atom(), map(), String.t()) :: {:ok | :error, any()}
  @callback configuration_present?() :: boolean()
end
