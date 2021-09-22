defmodule Mediasoup do
  @moduledoc """
  Documentation for `Mediasoup`.
  """
  alias Mediasoup.{Worker, Nif}

  @spec create_worker() :: {:ok, Worker.t()} | {:error, String.t()}
  def create_worker() do
    Nif.create_worker()
  end

  @spec create_worker(Worker.Settings.t() | Worker.create_option()) ::
          {:ok, Worker.t()} | {:error, String.t()}
  def create_worker(%Worker.Settings{} = settings) do
    Nif.create_worker(settings)
  end

  def create_worker(option) do
    Nif.create_worker(Worker.Settings.from_map(option))
  end
end
