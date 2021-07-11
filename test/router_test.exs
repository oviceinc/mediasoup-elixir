defmodule RouterTest do
  use ExUnit.Case

  test "create_router_succeeds" do
    IntegrateTest.RouterTest.create_router_succeeds()
  end

  test "router_dump" do
    IntegrateTest.RouterTest.router_dump()
  end

  test "close_event" do
    IntegrateTest.RouterTest.close_event()
  end
end
