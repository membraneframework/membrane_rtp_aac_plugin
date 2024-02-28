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

    defp run_test_inconsistent_sizes(frame, invalid_frame_size) do
      mode = :lbr
      header = <<invalid_frame_size::6, 0::2>>
      packet = <<bit_size(header)::16, header::binary, frame::binary>>

      {:ok, _supervisor_pid, pipeline_pid} =
        Membrane.Testing.Pipeline.start(spec: get_pipeline_spec(mode, [packet]))

      assert_sink_playing(pipeline_pid, :sink)
      pipeline_ref = Process.monitor(pipeline_pid)

      assert_receive(
        {:DOWN, ^pipeline_ref, :process, ^pipeline_pid,
         {:membrane_child_crash, :depayloader,
          {%RuntimeError{
             message: reason
           }, _}}},
        2000
      )

      assert String.match?(reason, ~r/:inconsistent_sizes/)
    end

    defp run_test_invalid_headers_length(frame, invalid_headers_length) do
      mode = :lbr
      header = <<bit_size(frame)::6, 0::2>>
      packet = <<invalid_headers_length::16, header::binary, frame::binary>>

      {:ok, _supervisor_pid, pipeline_pid} =
        Membrane.Testing.Pipeline.start(spec: get_pipeline_spec(mode, [packet]))

      assert_sink_playing(pipeline_pid, :sink)
      pipeline_ref = Process.monitor(pipeline_pid)

      assert_receive(
        {:DOWN, ^pipeline_ref, :process, ^pipeline_pid,
         {:membrane_child_crash, :depayloader, _reason}},
        2000
      )
    end

    test "when sending single packet with invalid frame size" do
      frame = <<1::8, 2::8>>
      run_test_inconsistent_sizes(frame, 0)
      run_test_inconsistent_sizes(frame, 1)
      run_test_inconsistent_sizes(frame, 55)
      run_test_inconsistent_sizes(frame, -2)
    end

    test "when sending single packet with invalid header length" do
      frame = <<1::8, 2::8>>
      run_test_invalid_headers_length(frame, -2)
      run_test_invalid_headers_length(frame, 0)
      run_test_invalid_headers_length(frame, 4)
      run_test_invalid_headers_length(frame, 12)
    end
  end
end
