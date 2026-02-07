defmodule Monolinc.Repo do
  use Ecto.Repo,
    otp_app: :monolinc,
    adapter: Ecto.Adapters.SQLite3
end
