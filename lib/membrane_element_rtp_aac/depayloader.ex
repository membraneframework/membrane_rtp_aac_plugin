defmodule Membrane.RTP.AAC.Depayloader do
  @moduledoc """
    Depayloader for RTP payloads constructed in accordance with RFC3640.
  """

  use Membrane.Filter
  alias Membrane.Buffer
  alias Membrane.{AAC, RTP}
  alias Membrane.RTP.AAC.Utils

  def_input_pad :input, accepted_format: %RTP{}
  def_output_pad :output, accepted_format: %AAC{encapsulation: :none}

  def_options mode: [
                spec: Utils.mode(),
                description: """
                The bitrate mode that dictates the maximum length of a single frame. For more information refer to Utils.mode()'s typedoc.
                """
              ]

  @impl true
  def handle_init(_ctx, options) do
    state =
      options
      |> Map.from_struct()

    {[], state}
  end

  @impl true
  def handle_stream_format(:input, _stream_fmt, _ctx, state) do
    {[stream_format: {:output, %AAC{}}], state}
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
