defmodule MonolincWeb.ChannelCase do
  @moduledoc """
  This module defines the test case to be used by
  channel tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ChannelTest
      import MonolincWeb.ChannelCase

      @endpoint MonolincWeb.Endpoint
    end
  end

  setup tags do
    Monolinc.DataCase.setup_sandbox(tags)
    :ok
  end
end
