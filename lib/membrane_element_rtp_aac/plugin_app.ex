defmodule Membrane.RTP.AAC.Plugin.App do
  @moduledoc false
  use Application
  alias Membrane.RTP.{AAC, PayloadFormat}

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    PayloadFormat.register(%PayloadFormat{
      encoding_name: :AAC,
      payload_type: 127,
      depayloader: AAC.Depayloader
    })

    PayloadFormat.register_payload_type_mapping(127, :AAC, 48_000)
    Supervisor.start_link([], strategy: :one_for_one, name: __MODULE__)
  end
end
