# Membrane RTP AAC Plugin

[![Star Membrane on GitHub ★](https://img.shields.io/github/stars/membraneframework/membrane_core?style=flat&logo=github&label=Star%20Membrane%20on%20GitHub%20%E2%98%85&color=blue)](https://github.com/membraneframework/membrane_core)
[![Hex.pm](https://img.shields.io/hexpm/v/membrane_rtp_aac_plugin.svg)](https://hex.pm/packages/membrane_rtp_aac_plugin)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_rtp_aac_plugin)
[![CI](https://github.com/membraneframework/membrane_rtp_aac_plugin/actions/workflows/ci.yml/badge.svg)](https://github.com/membraneframework/membrane_rtp_aac_plugin/actions/workflows/ci.yml)

This package provides elements that can be used for payloading and depayloading AAC audio in accordance with [RFC3640](https://datatracker.ietf.org/doc/html/rfc3640), using the mpeg4-generic payloading scheme.

It is part of [Membrane Multimedia Framework](https://membrane.stream).

## Installation

The package can be installed by adding `membrane_rtp_aac_plugin` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:membrane_rtp_aac_plugin, "~> 0.9.8"}
  ]
end
```

## Copyright and License

Copyright 2018, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_rtp_aac_plugin)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_rtp_aac_plugin)

Licensed under the [Apache License, Version 2.0](LICENSE)
