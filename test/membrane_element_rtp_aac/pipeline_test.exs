defmodule Membrane.RTP.AAC.Pipeline.Test do
  use ExUnit.Case, async: true

  import Membrane.ChildrenSpec
  import Membrane.Testing.Assertions

  describe "test payloader to depayloader is identity" do
    defp create_pipeline_supervised!(frames_per_packet, mode, payload) do
      spec = [
        child(:source, %Membrane.Testing.Source{
          output: payload,
          stream_format: %Membrane.AAC{}
        })
        |> child(:payloader, %Membrane.RTP.AAC.Payloader{mode: mode, frames_per_packet: frames_per_packet})
        |> child(:depayloader, %Membrane.RTP.AAC.Depayloader{mode: mode})
        |> child(:sink, Membrane.Testing.Sink)
      ]

      Membrane.Testing.Pipeline.start_link_supervised!(spec: spec)
    end

    def run_pipeline_test(frames_per_packet, mode, payload) do
      pipeline_pid = create_pipeline_supervised!(frames_per_packet, mode, payload)
      assert_sink_playing(pipeline_pid, :sink)

      assert_sink_buffer(pipeline_pid, :sink, %Membrane.Buffer{
        payload: ^payload
      })

      assert_end_of_stream(pipeline_pid, :sink)
    end

    test "when sending single packet, low bitrate mode",
      do: run_pipeline_test(1, :lbr, [<<1>>])
    test "when sending single packet, high bitrate mode",
      do: run_pipeline_test(1, :hbr, [<<1>>])

    test "when sending single packet, multiple frames, low bitrate mode",
      do: run_pipeline_test(2, :lbr, [<<1>>, <<2>>])
    test "when sending single packet, multiple frames, high bitrate mode",
      do: run_pipeline_test(2, :hbr, [<<1>>, <<2>>])

    # test "when sending multiple packets, multiple, frames, low bitrate mode",
    # TODO: test unhappy paths
  end
end
