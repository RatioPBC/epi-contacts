defmodule TestFunWithFlagsActor do
  @moduledoc """
  Fake actor for use in tests to simplify test setup
  """
  defstruct [:domain]

  def new(domain) do
    %__MODULE__{
      domain: domain
    }
  end
end

defimpl FunWithFlags.Actor, for: TestFunWithFlagsActor do
  def id(%{domain: domain}) do
    "domain:#{domain}"
  end
end
