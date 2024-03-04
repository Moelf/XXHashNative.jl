# XXHashNative.jl

[![Build Status](https://github.com/Moelf/XXHashNative.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Moelf/XXHashNative.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![codecov](https://codecov.io/gh/Moelf/XXHashNative.jl/graph/badge.svg?token=QnyBYvkeRN)](https://codecov.io/gh/Moelf/XXHashNative.jl)

For a wrapper package, see [XXhash.jl](https://github.com/hros/XXhash.jl).

We referred to the [reference spec](https://github.com/Cyan4973/xxHash/blob/v0.8.2/doc/xxhash_spec.md#xxh3-algorithm-overview) from the official repository.

This package provides native Julia implementations for some of the
[XXHash](https://github.com/Cyan4973/xxHash/) algorithms. Currently, only
one-shot hashing is supported. And see the following table for the supported
algorithms:

- [ ] XXH32
- [ ] XXH64
- [x] XXH3_64
- [ ] XXH3_128


## Example

```julia
julia> using XXHashNative: xxh3_64

# xxh3_64(input::AbstractVector{UInt8}, seed=UInt64(0), secret=XXHashNative._ksecret)
# xxh3_64(input::AbstractString, seed=UInt64(0), secret=XXHashNative._ksecret)

julia> xxh3_64(codeunits("Hello, world!"))
0xf3c34bf11915e869
julia> xxh3_64("Hello, world!")
0xf3c34bf11915e869
```

## Benchmark

Note: not particularly fast but fast enough

```julia
julia> using XXHashNative: xxh3_64

julia> using BenchmarkTools

julia> @benchmark xxh3_64(x) setup=(x=rand(UInt8, 2^20))
BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):  159.330 μs … 260.553 μs  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     165.581 μs               ┊ GC (median):    0.00%
 Time  (mean ± σ):   167.285 μs ±   6.255 μs  ┊ GC (mean ± σ):  0.00% ± 0.00%

      ▆█▇█▇▇▃▁▂▁
  ▁▁▄███████████████▇▇▇▇▆▅▄▄▄▄▃▃▃▂▂▂▂▂▂▂▂▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁ ▃
  159 μs           Histogram: frequency by time          191 μs <

 Memory estimate: 80 bytes, allocs estimate: 1.

julia> 1/0.159*1000
6289.30#MB/s

# for comparison, the wrapper XXhash.jl is 4 times faster
julia> 1/40.725*10^6
24554.94#MB/s
```
