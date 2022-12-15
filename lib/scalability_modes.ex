defmodule Mediasoup.ScalabilityMode do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#mediasoup-parseScalabilityMode
  """
  @type t :: %Mediasoup.ScalabilityMode{
          scalability_mode: nil | bitstring,
          spatial_layers: pos_integer,
          temporal_layers: pos_integer,
          ksvc: boolean()
        }
  defstruct spatial_layers: 1,
            temporal_layers: 1,
            scalability_mode: nil,
            ksvc: false

  def parse(str) do
    captures = Regex.run(~r/^[LS]([1-9][0-9]?)T([1-9][0-9]?)(_KEY)?/, str)

    case captures do
      [_, spatial_layers, temporal_layers, _kvc] ->
        %Mediasoup.ScalabilityMode{
          spatial_layers: String.to_integer(spatial_layers),
          temporal_layers: String.to_integer(temporal_layers),
          scalability_mode: str,
          ksvc: true
        }

      [_, spatial_layers, temporal_layers] ->
        %Mediasoup.ScalabilityMode{
          spatial_layers: String.to_integer(spatial_layers),
          temporal_layers: String.to_integer(temporal_layers),
          scalability_mode: str
        }

      _ ->
        %Mediasoup.ScalabilityMode{
          scalability_mode: str
        }
    end
  end
end
