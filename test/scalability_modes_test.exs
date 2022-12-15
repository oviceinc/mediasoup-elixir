defmodule ScalabilityModeTest do
  use ExUnit.Case
  import ExUnit.Assertions
  alias Mediasoup.ScalabilityMode

  test "parse" do
    assert %{spatial_layers: 1, temporal_layers: 3, ksvc: false} = ScalabilityMode.parse("L1T3")

    assert %{spatial_layers: 3, temporal_layers: 2, ksvc: true} =
             ScalabilityMode.parse("L3T2_KEY")

    assert %{spatial_layers: 2, temporal_layers: 3, ksvc: false} = ScalabilityMode.parse("S2T3")
    assert %{spatial_layers: 1, temporal_layers: 1, ksvc: false} = ScalabilityMode.parse("foo")
    assert %{spatial_layers: 1, temporal_layers: 1, ksvc: false} = ScalabilityMode.parse("")
    assert %{spatial_layers: 1, temporal_layers: 1, ksvc: false} = ScalabilityMode.parse("S0T3")
    assert %{spatial_layers: 1, temporal_layers: 1, ksvc: false} = ScalabilityMode.parse("S1T0")
    assert %{spatial_layers: 20, temporal_layers: 3, ksvc: false} = ScalabilityMode.parse("L20T3")
    assert %{spatial_layers: 1, temporal_layers: 1, ksvc: false} = ScalabilityMode.parse("S200T3")

    assert %{spatial_layers: 4, temporal_layers: 7, ksvc: true} =
             ScalabilityMode.parse("L4T7_KEY_SHIFT")
  end
end
