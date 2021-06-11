defmodule EpiContactsWeb.EmailQueue do
  @moduledoc false
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{last_email: nil}, name: __MODULE__)
  end

  def get_last_email do
    GenServer.call(__MODULE__, :get_last_email)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:get_last_email, _from, %{last_email: last_email} = state) do
    {:reply, last_email, state}
  end

  def handle_info({:delivered_email, email}, state) do
    {:noreply, %{state | last_email: email}}
  end
end
