defmodule MediasoupTest do
  use ExUnit.Case

  test "version/0 returns version string" do
    version = Mediasoup.version()
    assert is_binary(version)
    assert String.match?(version, ~r/^\d+\.\d+\.\d+$/)
  end

  test "get_supported_rtp_capabilities/0 returns a map with codecs" do
    caps = Mediasoup.get_supported_rtp_capabilities()
    assert is_map(caps)
    assert Map.has_key?(caps, "codecs"), "expected \"codecs\" key in #{inspect(caps)}"
    assert is_list(caps["codecs"])
    # header extensions may be under "headerExtensions" or "header_extensions"
    header_ext = caps["headerExtensions"] || caps["header_extensions"]
    if header_ext != nil, do: assert(is_list(header_ext))
  end
end
