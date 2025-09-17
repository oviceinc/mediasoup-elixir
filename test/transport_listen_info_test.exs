defmodule Mediasoup.TransportListenInfoTest do
  use ExUnit.Case

  alias Mediasoup.TransportListenInfo

  test "create" do
    assert %Mediasoup.TransportListenInfo{
             announcedAddress: "1.1.1.1",
             ip: "127.0.0.1",
             protocol: :udp,
             exposeInternalIp: false
           } ==
             TransportListenInfo.create(
               %{ip: "127.0.0.1", announcedAddress: "1.1.1.1"},
               :udp
             )

    assert %Mediasoup.TransportListenInfo{
             ip: "127.0.0.1",
             protocol: :tcp,
             exposeInternalIp: false
           } ==
             TransportListenInfo.create("127.0.0.1", :tcp)
  end
end
