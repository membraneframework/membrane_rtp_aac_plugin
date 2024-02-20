defmodule Membrane.RTP.AAC.Utils do
  use Bunch
  @moduledoc "__jm__"

  @type mode() :: :lbr | :hbr

  @spec make_headers([pos_integer()], mode()) :: binary()
  def make_headers(sizes, mode) do
    aus_count = length(sizes)
    {au_size_length, au_index_length} = bitrate_params(mode)
    header_length = au_size_length + au_index_length

    headers_length =
      aus_count * header_length

    # __jm__ support interleaving?
    au_index_deltas = List.duplicate(0, aus_count)

    headers =
      Enum.zip_with(sizes, au_index_deltas, fn au_size, au_index ->
        <<au_size::size(au_size_length), au_index::size(au_index_length)>>
      end)
      |> :binary.list_to_bin()

    <<headers_length::16>> <> headers
  end

  @spec parse_packet(binary(), any()) :: {:ok, [binary()]} | {:error, any()}
  def parse_packet(packet, mode) do
    <<headers_length::16, header_section::bits-size(headers_length), au_data_section::binary>> =
      packet

    {au_size_length, au_index_length} = bitrate_params(mode)

    # @type headers :: [{integer(), integer()}]
    # __jm__ are inline type hints possible?
    headers =
      for <<au_size::size(au_size_length), au_index::size(au_index_length) <- header_section>>,
        do: {au_size, au_index}

    {au_sizes, au_indices} = headers |> Enum.unzip()

    with true <-
           validate_deltas(au_indices)
           ~>> (false -> {:invalid_deltas, au_indices}),
         true <-
           validate_sizes(au_sizes, au_data_section)
           ~>> (false -> {:inconsistent_sizes, au_sizes, au_data_section}),
         do: parse_data_section(au_sizes, au_data_section),
         else: (reason -> {:error, {"Validation failed:", reason}})
  end

  @spec parse_data_section([pos_integer()], binary()) :: {:ok, [binary()]} | {:error, any()}
  defp parse_data_section(au_sizes, au_data_section) do
    result =
      Bunch.Enum.try_map_reduce(au_sizes, au_data_section, fn len, data ->
        case data do
          <<au::binary-size(len), rest::binary>> -> {{:ok, au}, rest}
          _else -> {{:error, "Couldn't consume remaining data"}, data}
        end
      end)

    case result do
      {{:ok, aus}, <<>>} -> {:ok, aus}
      # __jm__ is left more typical?
      {{:error, reason}, data} -> {:error, {reason, data}}
      # __jm__ like what?
      _else -> raise "Unexpected scenario"
    end
  end

  @spec validate_deltas([integer()]) :: boolean()
  defp validate_deltas(au_indices),
    do: au_indices == List.duplicate(0, length(au_indices))

  @spec validate_sizes([pos_integer()], binary()) :: boolean()
  defp validate_sizes(au_sizes, au_data_section),
    # __jm__ support interleaving?
    do: Enum.sum(au_sizes) == byte_size(au_data_section)

  @spec bitrate_params(mode()) ::
          {au_size_length :: pos_integer(), au_index_length :: pos_integer()}
  defp bitrate_params(:lbr), do: {6, 2}
  defp bitrate_params(:hbr), do: {13, 3}
end
