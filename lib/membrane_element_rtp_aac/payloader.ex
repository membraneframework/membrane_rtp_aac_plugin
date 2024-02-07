defmodule Membrane.RTP.AAC.Payloader do
  @moduledoc "TODO"

  use Membrane.Filter

  alias Membrane.Buffer
  alias Membrane.{AAC, RTP}

  def_input_pad :input, accepted_format: %AAC{encapsulation: :none}
  def_output_pad :output, accepted_format: %RTP{}

  @impl true
  def handle_init(_ctx, _options) do
    {_actions = [], _state = %{}}
  end

  @impl true
  def handle_stream_format(:input, _stream_fmt, _ctx, state) do
    {[stream_format: {:output, %RTP{}}], state}
  end

  @impl true
  def handle_demand(:output, size, :buffers, _ctx, state) do
    {[demand: {:input, size}], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    {[buffer: {:output, %Buffer{buffer | payload: wrap_aac(buffer.payload)}}], state}
  end

  @spec wrap_aac(binary()) :: binary()
  defp wrap_aac(au) do
    <<16::16, byte_size(au)::13, _au_index = 0::3>> <> au
  end
end
