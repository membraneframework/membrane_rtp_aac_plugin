defmodule Membrane.RTP.AAC.Pipeline.Test do
  @moduledoc false

  use ExUnit.Case, async: true

  import Membrane.ChildrenSpec
  import Membrane.Testing.Assertions

  describe "test payloader to depayloader is identity" do
    defp get_pipeline_spec(frames_per_packet, mode, payload) do
      child(:source, %Membrane.Testing.Source{
        output: payload,
        stream_format: %Membrane.AAC{}
      })
      |> child(:payloader, %Membrane.RTP.AAC.Payloader{
        mode: mode,
        frames_per_packet: frames_per_packet
      })
      |> child(:depayloader, %Membrane.RTP.AAC.Depayloader{mode: mode})
      |> child(:sink, Membrane.Testing.Sink)
    end

    defp run_pipeline_expect_success(frames_per_packet, mode, payload) do
      pipeline_pid =
        Membrane.Testing.Pipeline.start_link_supervised!(
          spec: get_pipeline_spec(frames_per_packet, mode, payload)
        )

      assert_sink_playing(pipeline_pid, :sink)

      assert_sink_buffer(pipeline_pid, :sink, %Membrane.Buffer{
        payload: ^payload
      })

      assert_end_of_stream(pipeline_pid, :sink)
      Membrane.Pipeline.terminate(pipeline_pid)
    end

    defp run_pipeline_expect_frames_too_long(frames_per_packet, mode, payload) do
      # NOTE: must start pipeline unsupervised to capture logs correctly
      {:ok, _supervisor_pid, pipeline_pid} =
        Membrane.Testing.Pipeline.start(spec: get_pipeline_spec(frames_per_packet, mode, payload))

      assert_sink_playing(pipeline_pid, :sink)
      pipeline_ref = Process.monitor(pipeline_pid)

      assert_receive(
        {:DOWN, ^pipeline_ref, :process, ^pipeline_pid,
         {:membrane_child_crash, :payloader,
          {%RuntimeError{
             message: "Received frames are too long for the chosen bitrate mode"
           }, _}}},
        2000
      )
    end

    test "when sending single packet, low bitrate mode",
      do: run_pipeline_expect_success(1, :lbr, [<<1>>])

    test "when sending single packet, high bitrate mode",
      do: run_pipeline_expect_success(1, :hbr, [<<1>>])

    test "when sending single packet, multiple frames, low bitrate mode",
      do: run_pipeline_expect_success(2, :lbr, [<<1>>, <<2>>])

    test "when sending single packet, multiple framess, high bitrate mode",
      do: run_pipeline_expect_success(2, :hbr, [<<1>>, <<2>>])

    test "when sending single packet, low bitrate mode, frame exceeds allowed size",
      do: run_pipeline_expect_frames_too_long(1, :lbr, [<<1::size(64)-unit(8)>>])

    test "when sending single packet, high bitrate mode, frame exceeds allowed size",
      do: run_pipeline_expect_frames_too_long(1, :hbr, [<<1::size(8192)-unit(8)>>])
  end
end
