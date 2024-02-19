defmodule Membrane.RTP.AAC.Depayloader do
  @moduledoc "TODO"

  use Membrane.Filter
  alias Membrane.Buffer
  alias Membrane.{AAC, RTP}

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
              bitrate: [
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
  def handle_demand(:output, size, :buffers, _ctx, state) do
    {[demand: {:input, size}], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    with {:ok, payload} <- parse_packet(buffer.payload, state.bitrate) do
      {[buffer: {:output, %Buffer{buffer | payload: payload}}], state}
    else
      {:error, reason} -> raise "Cannot parse packet due to: #{inspect(reason)}"
    end
  end

  @spec parse_packet(binary(), :lbr | :hbr) :: {:ok, [binary()]} | {:error, t()}
  defp parse_packet(packet, bitrate) do
    <<headers_length::16, headers::binary-size(headers_length), packet::binary>> = packet
    # now I need to know if is hbr (au_size::13, au_index::3) or lbr (au_size::6, au_index::2)
    {au_size_length, au_index_length} = bitrate_params(bitrate)
    header_length = au_size_length + au_index_length

    headers =
      for <<au_size::binary-size(au_size_length),
            au_index::binary-size(au_index_length) <- headers>>,
          do: {au_size, au_index}

    # indices should all be one if in order?
    lengths =
      with headers_count = div(headers_length, header_length),
           ones = List.duplicate(1, headers_count - 1),
           {lengths, [0 | ^ones]} <- Enum.unzip(headers),
           do: lengths

    if Enum.sum(lengths) == Kernel.byte_size(packet) do
      {:ok, partition(packet, lengths)}
    else
      {:error, :invalid_packet}
    end
  end

  @spec partition(binary(), [pos_integer()], [binary()]) :: [binary()]
  defp partition(binary_, lengths_, acc \\ [])
  defp partition(<<>>, [], acc), do: acc

  defp partition(binary_, [n | lengths], acc) do
    <<next_::binary-size(n), binary_::bitstring>> = binary_
    partition(binary_, lengths, [next_ | acc])
  end

  @spec bitrate_params(:lbr | :hbr) ::
          {au_size_length :: pos_integer(), au_index_length :: pos_integer()}
  defp bitrate_params(:lbr), do: {6, 2}
  defp bitrate_params(:hbr), do: {13, 3}
end
