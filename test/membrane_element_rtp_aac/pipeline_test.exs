defmodule Membrane.RTP.AAC.Pipeline.Test do
  use ExUnit.Case, async: true

  import Membrane.ChildrenSpec
  import Membrane.Testing.Assertions

  defp prepare_test_payload(_ctx) do
    %{
      payload: [<<1>>]
    }
  end

  setup :prepare_test_payload

  test "payloader to depayloader does not change source", ctx do
    spec = [
      child(:source, %Membrane.Testing.Source{output: ctx.payload, stream_format: %Membrane.AAC{}})
      |> child(:payloader, %Membrane.RTP.AAC.Payloader{mode: :lbr, frames_per_packet: 1})
      |> child(:depayloader, %Membrane.RTP.AAC.Depayloader{mode: :lbr})
      |> child(:sink, Membrane.Testing.Sink)
    ]

    pipeline_pid = Membrane.Testing.Pipeline.start_link_supervised!(spec: spec)

    assert_start_of_stream(pipeline_pid, :sink)

    assert_sink_buffer(pipeline_pid, :sink, %Membrane.Buffer{
      payload: [<<1::8>>]
    })

    assert_end_of_stream(pipeline_pid, :sink)
  end
end
