# XXHashNative.jl

[![Build Status](https://github.com/Moelf/XXHashNative.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Moelf/XXHashNative.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Codecov](https://codecov.io/gh/Moelf/XXHashNative.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/Moelf/XXHashNative.jl)

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
