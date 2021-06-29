defmodule Mediasoup.Consumer do
  alias Mediasoup.{Consumer, Nif}
  @enforce_keys [:id, :producer_id, :kind, :type, :rtp_parameters, :reference]
  defstruct [:id, :producer_id, :kind, :type, :rtp_parameters, :reference]

  @type t(id, producer_id, kind, type, rtp_parameters, ref) :: %Consumer{
          id: id,
          producer_id: producer_id,
          kind: kind,
          type: type,
          rtp_parameters: rtp_parameters,
          reference: ref
        }
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
  def close(consumer) do
    Nif.consumer_close(consumer.reference)
  end

  @spec dump(t) :: map | {:error}
  def dump(consumer) do
    Nif.consumer_dump(consumer.reference)
  end

  @spec closed?(t) :: boolean
  def closed?(consumer) do
    Nif.consumer_closed(consumer.reference)
  end

  @spec paused?(t) :: boolean
  def paused?(consumer) do
    Nif.consumer_paused(consumer.reference)
  end

  @spec producer_paused?(t) :: boolean
  def producer_paused?(consumer) do
    Nif.consumer_producer_paused(consumer.reference)
  end

  @spec priority(t) :: number
  def priority(consumer) do
    Nif.consumer_priority(consumer.reference)
  end

  @spec score(t) :: map
  def score(consumer) do
    Nif.consumer_score(consumer.reference)
  end

  @spec preferred_layers(t) :: any
  def preferred_layers(consumer) do
    Nif.consumer_preferred_layers(consumer.reference)
  end

  @spec current_layers(t) :: any
  def current_layers(consumer) do
    Nif.consumer_current_layers(consumer.reference)
  end

  @spec get_stats(t) :: any
  def get_stats(consumer) do
    Nif.consumer_get_stats(consumer.reference)
  end

  @spec pause(t) :: {:ok} | {:error}
  def pause(consumer) do
    Nif.consumer_pause(consumer.reference)
  end

  @spec resume(t) :: {:ok} | {:error}
  def resume(consumer) do
    Nif.consumer_resume(consumer.reference)
  end

  @spec set_preferred_layers(t, map) :: {:ok} | {:error}
  def set_preferred_layers(consumer, layer) do
    Nif.consumer_set_preferred_layers(consumer.reference, layer)
  end

  @spec set_priority(t, integer) :: {:ok} | {:error}
  def set_priority(consumer, priority) do
    Nif.consumer_set_priority(consumer.reference, priority)
  end

  @spec unset_priority(t) :: {:ok} | {:error}
  def unset_priority(consumer) do
    Nif.consumer_unset_priority(consumer.reference)
  end

  @spec request_key_frame(t) :: {:ok} | {:error}
  def request_key_frame(consumer) do
    Nif.consumer_request_key_frame(consumer.reference)
  end

  @spec event(t, pid) :: {:ok} | {:error}
  def event(consumer, pid) do
    Nif.consumer_event(consumer.reference, pid)
  end
end
