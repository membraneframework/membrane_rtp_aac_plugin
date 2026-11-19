defmodule Membrane.RTP.AAC.Depayloader.Test do
  @moduledoc false

  use ExUnit.Case, async: true

  import Membrane.ChildrenSpec
  import Membrane.Testing.Assertions

  describe "depayloader" do
    defp get_pipeline_spec(mode, payload) do
      child(:source, %Membrane.Testing.Source{
        output: payload,
        stream_format: %Membrane.RTP{}
      })
      |> child(:depayloader, %Membrane.RTP.AAC.Depayloader{mode: mode})
      |> child(:sink, Membrane.Testing.Sink)
    end

    defp assert_dropped(malformed_packet) do
      frame = <<1::8, 2::8>>
      header = <<byte_size(frame)::6, 0::2>>
      valid_packet = <<bit_size(header)::16, header::binary, frame::binary>>

      pipeline =
        Membrane.Testing.Pipeline.start_link_supervised!(
          spec: get_pipeline_spec(:lbr, [malformed_packet, valid_packet])
        )

      assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: ^frame})
      assert_end_of_stream(pipeline, :sink)
      refute_sink_buffer(pipeline, :sink, _buffer, 0)
      Membrane.Testing.Pipeline.terminate(pipeline)
    end

    test "drops a packet with an invalid frame size" do
      frame = <<1::8, 2::8>>

      for invalid_frame_size <- [0, 1, 55, -2] do
        header = <<invalid_frame_size::6, 0::2>>
        assert_dropped(<<bit_size(header)::16, header::binary, frame::binary>>)
      end
    end

    test "drops a packet with an invalid header length" do
      frame = <<1::8, 2::8>>
      header = <<bit_size(frame)::6, 0::2>>

      for invalid_headers_length <- [-2, 0, 4, 12] do
        assert_dropped(<<invalid_headers_length::16, header::binary, frame::binary>>)
      end
    end

    test "drops packets it cannot parse, logs them and carries on" do
      import ExUnit.CaptureLog

      frame = <<1::8, 2::8>>
      header = <<byte_size(frame)::6, 0::2>>
      valid = <<bit_size(header)::16, header::binary, frame::binary>>

      malformed = [
        # no room for the AU headers length
        <<1>>,
        # AU headers length larger than the packet
        <<4000::16, header::binary, frame::binary>>,
        # the AU size disagrees with the data that follows
        <<bit_size(header)::16, 55::6, 0::2, frame::binary>>,
        <<>>
      ]

      spec =
        child(:source, %Membrane.Testing.Source{
          output: [valid] ++ malformed ++ [valid],
          stream_format: %Membrane.RTP{}
        })
        |> child(:depayloader, %Membrane.RTP.AAC.Depayloader{mode: :lbr})
        |> child(:sink, Membrane.Testing.Sink)

      log =
        capture_log(fn ->
          pipeline = Membrane.Testing.Pipeline.start_link_supervised!(spec: spec)

          assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: ^frame})
          assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: ^frame})
          assert_end_of_stream(pipeline, :sink)
          refute_sink_buffer(pipeline, :sink, _buffer, 0)
          Membrane.Testing.Pipeline.terminate(pipeline)
        end)

      assert log =~ "Dropping an RTP packet"
    end
  end
end
