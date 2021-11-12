defmodule NifWrapEventProxyTest do
  use ExUnit.Case
  alias Mediasoup.NifWrap.EventProxy

  test "message proxy" do
    {:ok, proxy} = EventProxy.start(pid: self())

    send(proxy, {:on_close})

    assert_receive {:on_close}
  end

  test "exit" do
    {:ok, proxy} = EventProxy.start(pid: self())

    send(proxy, {:EXIT, self(), :normal})

    Process.alive?(proxy)
  end
end
