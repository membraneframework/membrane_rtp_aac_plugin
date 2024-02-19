defmodule Membrane.RTP.AAC.Utils.Test do
  use ExUnit.Case, async: true

  alias Membrane.RTP.AAC.Utils

  describe "make_headers" do
    test "when low bitrate mode" do
      assert match?(
               <<32::16>> <>
                 <<1::6, 0::2>> <>
                 <<2::6, 1::2>> <>
                 <<3::6, 1::2>> <>
                 <<4::6, 1::2>>,
               Utils.make_headers(1..4 |> Enum.to_list(), :lbr)
             )
    end

    test "when high bitrate mode" do
      assert match?(
               <<64::16>> <>
                 <<1::13, 0::3>> <>
                 <<2::13, 1::3>> <>
                 <<3::13, 1::3>> <>
                 <<4::13, 1::3>>,
               Utils.make_headers(1..4 |> Enum.to_list(), :hbr)
             )
    end
  end

  describe "parse_packet" do
    test "when low bitrate mode" do
      aus = [<<1>>, <<2>>]

      packet =
        <<_headers_length = 16::16>> <>
          <<_au1_size = 1::6, _au1_index = 0::2>> <>
          <<_au2_size = 1::6, _au2_delta = 1::2>> <>
          <<1, 2>>

      assert {:ok, aus} ==
               Utils.parse_packet(packet, :lbr)
    end

    test "when high bitrate mode" do
      aus = [<<1>>, <<2>>]

      packet =
        <<_headers_length = 32::16>> <>
          <<_au1_size = 1::13, _au1_index = 0::3>> <>
          <<_au2_size = 1::13, _au2_delta = 1::3>> <>
          <<1, 2>>

      assert {:ok, aus} ==
               Utils.parse_packet(packet, :hbr)
    end
  end
end
