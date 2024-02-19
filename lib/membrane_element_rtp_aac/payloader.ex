defmodule Membrane.RTP.AAC.Payloader do
  @moduledoc "TODO"

  use Membrane.Filter

  alias Membrane.Buffer
  alias Membrane.{AAC, RTP}

  def_input_pad :input, accepted_format: %AAC{encapsulation: :none}
  def_output_pad :output, accepted_format: %RTP{}

  def_options bitrate: [
                spec: :lbr | :hbr
              ],
              frames_per_packet: [
                spec: pos_integer()
              ]

  @impl true
  def handle_init(_ctx, options) do
    state =
      options
      |> Map.from_struct()
      |> Map.put(:acc, [])

    {_actions = [], state}
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
    @type buffer.payload :: binary()
    acc = [buffer.payload | state.acc]

    if length(acc) == state.frames_per_packet do
      {[buffer: {:output, %Buffer{buffer | payload: wrap_aac(acc, state)}}], %{state | acc: []}}
    else
      {[], %{state | acc: acc}}
    end
  end

  @spec wrap_aac([binary()], map()) :: binary()
  defp wrap_aac(aus, state) do
    au_lenghts = aus |> Enum.map(&byte_size/1)
    make_headers(au_lenghts, state.bitrate) <> :binary.list_to_bin(aus)
  end

  @spec make_headers([pos_integer()], :lbr | :hbr) :: binary()
  defp make_headers(lengths, bitrate) do
    aus_count = length(lengths)
    {au_size_length, au_index_length} = bitrate_params(bitrate)
    header_length = au_size_length + au_index_length

    headers_length =
      aus_count * header_length

    deltas = List.duplicate(1, header_length - 1)

    headers =
      for {au_size, au_index} <- Enum.zip([lengths, [0 | deltas]]) do
        <<au_size::size(au_size_length), au_index::size(au_index_length)>>
      end
      |> :binary.list_to_bin()

    <<headers_length::16>> <> headers
  end

  @spec bitrate_params(:lbr | :hbr) ::
          {au_size_length :: pos_integer(), au_index_length :: pos_integer()}
  defp bitrate_params(:lbr), do: {6, 2}
  defp bitrate_params(:hbr), do: {13, 3}
end
