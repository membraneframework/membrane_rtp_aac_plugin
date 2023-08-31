defmodule Membrane.RTP.AAC.Depayloader do
  @moduledoc false

  use Membrane.Filter
  alias Membrane.Buffer
  alias Membrane.{AAC, RTP}

  def_input_pad :input,
    demand_unit: :buffers,
    accepted_format: RTP

  def_output_pad :output,
    accepted_format: %AAC{encapsulation: :none}

  def_options profile: [
                default: :LC
              ],
              sample_rate: [
                default: 44_100
              ],
              channels: [
                default: 2
              ]

  @impl true
  def handle_init(_ctx, options) do
    {[], Map.merge(options, %{leftover: <<>>})}
  end

  @impl true
  def handle_stream_format(:input, _stream_format, _ctx, state) do
    stream_format = %AAC{
      profile: state.profile,
      sample_rate: state.sample_rate,
      channels: state.channels
    }

    {[stream_format: {:output, stream_format}], state}
  end

  @impl true
  def handle_demand(:output, size, :buffers, _ctx, state) do
    {[demand: {:input, size}], state}
  end

  @impl true
  def handle_process(:input, buffer, _ctx, state) do
    {[buffer: {:output, %Buffer{buffer | payload: parse_packet(buffer.payload)}}], state}
  end

  defp parse_packet(packet) do
    headers_length = 16
    <<^headers_length::16, au_size::13, _au_index::3, au::binary-size(au_size)>> = packet
    au
  end
end
