defmodule Mediasoup do
  @moduledoc """
  Documentation for `Mediasoup`.
  """
  alias Mediasoup.{Worker, Nif}

  @spec create_worker() :: {:ok, Worker.t()} | {:error, String.t()}
  def create_worker() do
    Nif.create_worker()
  end

  @spec create_worker(Worker.create_option()) :: {:ok, Worker.t()} | {:error, String.t()}
  def create_worker(option) do
    Nif.create_worker(option)
  end
end
