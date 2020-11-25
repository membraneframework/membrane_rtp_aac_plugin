defmodule Membrane.RTP.AAC.Depayloader do
  use Membrane.Filter
  alias Membrane.Buffer
  alias Membrane.{AAC, RemoteStream, RTP}

  def_input_pad :input, demand_unit: :buffers, caps: RTP
  def_output_pad :output, caps: {RemoteStream, content_format: AAC, type: :packetized}

  @impl true
  def handle_init(_options) do
    {:ok, %{}}
  end

  @impl true
  def handle_demand(:output, size, :buffers, _ctx, state) do
    {{:ok, demand: {:input, size}}, state}
  end

  @impl true
  def handle_caps(:input, _caps, _ctx, state) do
    caps = %RemoteStream{content_format: AAC, type: :packetized}
    {{:ok, caps: {:output, caps}}, state}
  end

  @impl true
  def handle_process(:input, buffer, _ctx, state) do
    with {:ok, payload} <- parse_packet(buffer.payload) do
      {{:ok, buffer: {:output, %Buffer{buffer | payload: payload}}}, state}
    else
      {:error, reason} -> {{:error, reason}, state}
    end
  end

  defp parse_packet(packet) do
    headers_length = 16

    with <<^headers_length::16, au_size::13, _au_index::3, au::binary-size(au_size)>> <-
           packet do
      {:ok, au}
    else
      _ -> {:error, :invalid_packet}
    end
  end
end
