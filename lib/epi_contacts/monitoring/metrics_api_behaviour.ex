defmodule EpiContacts.Monitoring.MetricsAPIBehaviour do
  @moduledoc """
  Provides a mockable interface around metrics reporting
  """
  @callback send(any(), Keyword.t()) :: any()
end
