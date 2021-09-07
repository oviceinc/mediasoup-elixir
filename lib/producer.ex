defmodule Mediasoup.Producer do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#Producer
  """
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
  def close(%Producer{reference: reference}) do
    Nif.producer_close(reference)
  end

  @spec dump(t) :: map
  def dump(%Producer{reference: reference}) do
    Nif.producer_dump(reference)
  end

  @spec pause(t) :: {:ok} | {:error}
  def pause(%Producer{reference: reference}) do
    Nif.producer_pause(reference)
  end

  @spec resume(t) :: {:ok} | {:error}
  def resume(%Producer{reference: reference}) do
    Nif.producer_resume(reference)
  end

  @spec score(t) :: list() | {:error}
  def score(%Producer{reference: reference}) do
    Nif.producer_score(reference)
  end

  @spec get_stats(t) :: list() | {:error}
  def get_stats(%Producer{reference: reference}) do
    Nif.producer_get_stats(reference)
  end

  @spec closed?(t) :: boolean()
  def closed?(%Producer{reference: reference}) do
    Nif.producer_closed(reference)
  end

  @spec paused?(t) :: boolean() | {:error}
  def paused?(%Producer{reference: reference}) do
    Nif.producer_paused(reference)
  end

  @spec event(t, pid) :: {:ok} | {:error}
  def event(%Producer{reference: reference}, pid) do
    Nif.producer_event(reference, pid)
  end
end
