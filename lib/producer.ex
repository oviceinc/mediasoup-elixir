defmodule Mediasoup.Producer do
  alias Mediasoup.{Producer, Nif}
  @enforce_keys [:id, :reference]
  defstruct [:id, :reference]
  @type t(id, ref) :: %Producer{id: id, reference: ref}
  @type t :: %Producer{id: String.t(), reference: reference}

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

  @spec event(t, pid) :: {:ok} | {:error}
  def event(producer, pid) do
    Nif.producer_event(producer.reference, pid)
  end
end
