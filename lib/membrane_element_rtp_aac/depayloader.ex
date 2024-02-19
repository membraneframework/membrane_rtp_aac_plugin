defmodule Membrane.RTP.AAC.Depayloader do
  @moduledoc "TODO"

  use Membrane.Filter
  alias Membrane.Buffer
  alias Membrane.{AAC, RTP}
  alias Membrane.RTP.AAC.Utils

  def_input_pad :input, accepted_format: %RTP{}
  def_output_pad :output, accepted_format: %AAC{encapsulation: :none}

  def_options profile: [
                default: :LC
              ],
              sample_rate: [
                default: 44_100
              ],
              channels: [
                default: 2
              ],
              mode: [
                spec: :lbr | :hbr
              ]

  @impl true
  def handle_init(_ctx, options) do
    state =
      options
      |> Map.from_struct()
      |> Map.put(:leftover, <<>>)

    {[], state}
  end

  @impl true
  def handle_stream_format(:input, _stream_fmt, _ctx, state) do
    stream_fmt = %AAC{
      profile: state.profile,
      sample_rate: state.sample_rate,
      channels: state.channels
    }

    {[stream_format: {:output, stream_fmt}], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    with {:ok, payload} <- Utils.parse_packet(buffer.payload, state.mode) do
      {[buffer: {:output, %Buffer{buffer | payload: payload}}], state}
    else
      {:error, reason} -> raise "Cannot parse packet due to: #{inspect(reason)}"
    end
  end
end
