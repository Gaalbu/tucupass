defmodule TucupassWeb.Presence do
  use Phoenix.Presence, otp_app: :tucupass, pubsub_server: Tucupass.PubSub
end
