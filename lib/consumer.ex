defmodule Mediasoup.Consumer do
  alias Mediasoup.{Consumer, Nif}
  @enforce_keys [:id, :producer_id, :kind, :type, :rtp_parameters, :reference]
  defstruct [:id, :producer_id, :kind, :type, :rtp_parameters, :reference]

  @type t :: %Consumer{
          id: String.t(),
          producer_id: String.t(),
          kind: kind,
          type: type,
          rtp_parameters: rtpParameters,
          reference: reference
        }

  @type rtpParameters :: map

  @typedoc """
    audio or video
  """
  @type kind :: String.t()
  @type type :: String.t()

  @spec close(t) :: {:ok} | {:error}
  def close(%Consumer{reference: reference}) do
    Nif.consumer_close(reference)
  end

  @spec dump(t) :: map | {:error}
  def dump(%Consumer{reference: reference}) do
    Nif.consumer_dump(reference)
  end

  @spec closed?(t) :: boolean
  def closed?(%Consumer{reference: reference}) do
    Nif.consumer_closed(reference)
  end

  @spec paused?(t) :: boolean
  def paused?(%Consumer{reference: reference}) do
    Nif.consumer_paused(reference)
  end

  @spec producer_paused?(t) :: boolean
  def producer_paused?(%Consumer{reference: reference}) do
    Nif.consumer_producer_paused(reference)
  end

  @spec priority(t) :: number
  def priority(%Consumer{reference: reference}) do
    Nif.consumer_priority(reference)
  end

  @spec score(t) :: map
  def score(%Consumer{reference: reference}) do
    Nif.consumer_score(reference)
  end

  @spec preferred_layers(t) :: any
  def preferred_layers(%Consumer{reference: reference}) do
    Nif.consumer_preferred_layers(reference)
  end

  @spec current_layers(t) :: any
  def current_layers(%Consumer{reference: reference}) do
    Nif.consumer_current_layers(reference)
  end

  @spec get_stats(t) :: any
  def get_stats(%Consumer{reference: reference}) do
    Nif.consumer_get_stats(reference)
  end

  @spec pause(t) :: {:ok} | {:error}
  def pause(%Consumer{reference: reference}) do
    Nif.consumer_pause(reference)
  end

  @spec resume(t) :: {:ok} | {:error}
  def resume(%Consumer{reference: reference}) do
    Nif.consumer_resume(reference)
  end

  @spec set_preferred_layers(t, map) :: {:ok} | {:error}
  def set_preferred_layers(%Consumer{reference: reference}, layer) do
    Nif.consumer_set_preferred_layers(reference, layer)
  end

  @spec set_priority(t, integer) :: {:ok} | {:error}
  def set_priority(%Consumer{reference: reference}, priority) do
    Nif.consumer_set_priority(reference, priority)
  end

  @spec unset_priority(t) :: {:ok} | {:error}
  def unset_priority(%Consumer{reference: reference}) do
    Nif.consumer_unset_priority(reference)
  end

  @spec request_key_frame(t) :: {:ok} | {:error}
  def request_key_frame(%Consumer{reference: reference}) do
    Nif.consumer_request_key_frame(reference)
  end

  @spec event(t, pid) :: {:ok} | {:error}
  def event(%Consumer{reference: reference}, pid) do
    Nif.consumer_event(reference, pid)
  end
end
