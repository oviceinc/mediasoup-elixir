defmodule Mediasoup.Producer do
  alias Mediasoup.{Producer, Nif}
  @enforce_keys [:id, :kind, :type, :rtp_parameters, :reference]
  defstruct [:id, :kind, :type, :rtp_parameters, :reference]

  @type t :: %Producer{
          id: String.t(),
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
  def close(producer) do
    Nif.producer_close(producer.reference)
  end

  @spec dump(t) :: map
  def dump(producer) do
    Nif.producer_dump(producer.reference)
  end

  @spec pause(t) :: {:ok} | {:error}
  def pause(producer) do
    Nif.producer_pause(producer.reference)
  end

  @spec resume(t) :: {:ok} | {:error}
  def resume(producer) do
    Nif.producer_resume(producer.reference)
  end

  @spec score(t) :: list() | {:error}
  def score(producer) do
    Nif.producer_score(producer.reference)
  end

  @spec get_stats(t) :: list() | {:error}
  def get_stats(producer) do
    Nif.producer_get_stats(producer.reference)
  end

  @spec closed?(t) :: boolean()
  def closed?(producer) do
    Nif.producer_closed(producer.reference)
  end

  @spec paused?(t) :: boolean() | {:error}
  def paused?(producer) do
    Nif.producer_paused(producer.reference)
  end

  @spec event(t, pid) :: {:ok} | {:error}
  def event(producer, pid) do
    Nif.producer_event(producer.reference, pid)
  end
end
