defmodule Mediasoup do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/
  """

  @version Mix.Project.config()[:version]
  def version(), do: @version

  @type num_sctp_streams :: %{OS: integer(), MIS: integer()}
  @type transport_listen_ip :: %{:ip => String.t(), optional(:announcedIp) => String.t() | nil}
end
