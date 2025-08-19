module XXHashNative
# Public exports
export xxh3_64
# Julia re-write
using StaticArrays: @MVector, @SVector, SVector

# (No SIMD dependency)

# Unaligned loads without pointers; manual byte assembly (little-endian)
Base.@propagate_inbounds @inline function loadu32(bytes::AbstractVector{UInt8}, offset::Int)
    @inbounds begin
        return UInt32(bytes[offset]) |
               (UInt32(bytes[offset+1]) << 8) |
               (UInt32(bytes[offset+2]) << 16) |
               (UInt32(bytes[offset+3]) << 24)
    end
end

Base.@propagate_inbounds @inline function loadu64(bytes::AbstractVector{UInt8}, offset::Int)
    @inbounds begin
        return UInt64(bytes[offset]) |
               (UInt64(bytes[offset+1]) << 8) |
               (UInt64(bytes[offset+2]) << 16) |
               (UInt64(bytes[offset+3]) << 24) |
               (UInt64(bytes[offset+4]) << 32) |
               (UInt64(bytes[offset+5]) << 40) |
               (UInt64(bytes[offset+6]) << 48) |
               (UInt64(bytes[offset+7]) << 56)
    end
end

# Specialized loads for static secrets (SVector doesn't provide pointer)
Base.@propagate_inbounds @inline function loadu32(bytes::SVector{N,UInt8}, offset::Int) where {N}
    @inbounds begin
        return UInt32(bytes[offset]) |
               (UInt32(bytes[offset+1]) << 8) |
               (UInt32(bytes[offset+2]) << 16) |
               (UInt32(bytes[offset+3]) << 24)
    end
end

Base.@propagate_inbounds @inline function loadu64(bytes::SVector{N,UInt8}, offset::Int) where {N}
    @inbounds begin
        return UInt64(bytes[offset]) |
               (UInt64(bytes[offset+1]) << 8) |
               (UInt64(bytes[offset+2]) << 16) |
               (UInt64(bytes[offset+3]) << 24) |
               (UInt64(bytes[offset+4]) << 32) |
               (UInt64(bytes[offset+5]) << 40) |
               (UInt64(bytes[offset+6]) << 48) |
               (UInt64(bytes[offset+7]) << 56)
    end
end

const PRIME32_1 = 0x9E3779B1
const PRIME32_2 = 0x85EBCA77
const PRIME32_3 = 0xC2B2AE3D
const PRIME64_1 = 0x9E3779B185EBCA87
const PRIME64_2 = 0xC2B2AE3D27D4EB4F
const PRIME64_3 = 0x165667B19E3779F9
const PRIME64_4 = 0x85EBCA77C2B2AE63
const PRIME64_5 = 0x27D4EB2F165667C5
const PRIME_MX1 = 0x165667919E3779F9
const PRIME_MX2 = 0x9FB21C651E98DF25
const _ksecret = @SVector[
        0xb8, 0xfe, 0x6c, 0x39, 0x23, 0xa4, 0x4b, 0xbe, 0x7c, 0x01, 0x81, 0x2c, 0xf7, 0x21, 0xad, 0x1c,
        0xde, 0xd4, 0x6d, 0xe9, 0x83, 0x90, 0x97, 0xdb, 0x72, 0x40, 0xa4, 0xa4, 0xb7, 0xb3, 0x67, 0x1f,
        0xcb, 0x79, 0xe6, 0x4e, 0xcc, 0xc0, 0xe5, 0x78, 0x82, 0x5a, 0xd0, 0x7d, 0xcc, 0xff, 0x72, 0x21,
        0xb8, 0x08, 0x46, 0x74, 0xf7, 0x43, 0x24, 0x8e, 0xe0, 0x35, 0x90, 0xe6, 0x81, 0x3a, 0x26, 0x4c,
        0x3c, 0x28, 0x52, 0xbb, 0x91, 0xc3, 0x00, 0xcb, 0x88, 0xd0, 0x65, 0x8b, 0x1b, 0x53, 0x2e, 0xa3,
        0x71, 0x64, 0x48, 0x97, 0xa2, 0x0d, 0xf9, 0x4e, 0x38, 0x19, 0xef, 0x46, 0xa9, 0xde, 0xac, 0xd8,
        0xa8, 0xfa, 0x76, 0x3f, 0xe3, 0x9c, 0x34, 0x3f, 0xf9, 0xdc, 0xbb, 0xc7, 0xc7, 0x0b, 0x4f, 0x1d,
        0x8a, 0x51, 0xe0, 0x4b, 0xcd, 0xb4, 0x59, 0x31, 0xc8, 0x9f, 0x7e, 0xc9, 0xd9, 0x78, 0x73, 0x64,
        0xea, 0xc5, 0xac, 0x83, 0x34, 0xd3, 0xeb, 0xc3, 0xc5, 0x81, 0xa0, 0xff, 0xfa, 0x13, 0x63, 0xeb,
        0x17, 0x0d, 0xdd, 0x51, 0xb7, 0xf0, 0xda, 0x49, 0xd3, 0x16, 0x55, 0x26, 0x29, 0xd4, 0x68, 0x9e,
        0x2b, 0x16, 0xbe, 0x58, 0x7d, 0x47, 0xa1, 0xfc, 0x8f, 0xf8, 0xb8, 0xd1, 0x7a, 0xd0, 0x31, 0xce,
        0x45, 0xcb, 0x3a, 0x8f, 0x95, 0x16, 0x04, 0x28, 0xaf, 0xd7, 0xfb, 0xca, 0xbb, 0x4b, 0x40, 0x7e,
    ]

# Use a Vector-backed default secret to enable fast pointer loads
const _ksecret_vec = Vector{UInt8}(_ksecret)

@inline function ifb32(bytes, offset = 0)
    return loadu32(bytes, offset)
end
@inline function ifb64(bytes, offset = 0)
    return loadu64(bytes, offset)
end

@inline function lowerhigher(x::UInt128)
    lo = UInt64(x & 0xffffffffffffffff)
    hi = UInt64(x >> 64)
    return (lo, hi)
end

@inline function lowerhigher(x::UInt64)
    lo = UInt32(x & 0xffffffff)
    hi = UInt32(x >> 32)
    return (lo, hi)
end

function _avalanche(h::UInt64)
    h = (h ⊻ (h >> 37)) * PRIME_MX1
    h = h ⊻ (h >> 32)
    return h
end

function _avalanche64(h::UInt64)
    h = (h ⊻ (h >> 33)) * PRIME64_2
    h = (h ⊻ (h >> 29)) * PRIME64_3
    return h ⊻ (h >> 32)
end

@inline function XXH3_64_empty(self)
    (; seed, secret) = self
    # Maintain prior offset convention to match reference vectors
    return _avalanche64(seed ⊻ ifb64(secret, 56 + 1) ⊻ ifb64(secret, 64 + 1))
end

@inline function XXH3_64_1to3(self)
    (; input, inputLength, secret, seed) = self

    b1 = UInt32(input[end])
    b2 = UInt32(inputLength) << 8
    b3 = UInt32(input[begin]) << 16
    b4 = UInt32(input[(inputLength >>> 1) + 1]) << 24
    combined = b1 | b2 | b3 | b4
    i1 = UInt64(ifb32(secret, 1) ⊻ ifb32(secret, 4 + 1)) + seed
    value = i1 ⊻ combined
    return _avalanche64(value)
end

@inline function XXH3_64_4to8(self)
    (; input, inputLength, secret, seed) = self

    inputFirst = ifb32(input, 1)
    inputLast = ifb32(input, inputLength - 4 + 1)

    lowerhalf, _ = lowerhigher(seed)
    modifiedSeed = seed ⊻ lowerhalf
    # secretWords[1], secretWords[2]
    s1 = loadu64(secret, 9)  # 8+1
    s2 = loadu64(secret, 17) # 16+1
    combined = UInt64(inputLast) | (UInt64(inputFirst) << 32)

    value = ((s1 ⊻ s2) - modifiedSeed) ⊻ combined
    value ⊻= ((value << 49) | (value >> 15)) ⊻ ((value << 24) | (value >> 40))
    value = value * PRIME_MX2
    value = value ⊻ ((value >> 35) + inputLength)
    value = value * PRIME_MX2
    value = value ⊻ (value >> 28)

    return value
end


@inline function XXH3_64_9to16(self)
    (; input, inputLength, secret, seed) = self

    inputFirst = ifb64(input, 1)
    inputLast = ifb64(input, inputLength - 8 + 1)

    # load 4 secret words starting at byte 25
    s1 = loadu64(secret, 25)
    s2 = loadu64(secret, 33)
    s3 = loadu64(secret, 41)
    s4 = loadu64(secret, 49)
    low = ((s1 ⊻ s2) + seed) ⊻ inputFirst
    high = ((s3 ⊻ s4) - seed) ⊻ inputLast

    mulResult = UInt128(low) * UInt128(high)
    lowerhalf, higherhalf = lowerhigher(mulResult)
    value = inputLength + bswap(low) + high + (lowerhalf ⊻ higherhalf)

    return _avalanche(value)
end

@inline function mixStep_ptr(input::AbstractVector{UInt8}, inputOffset::Int, secret::AbstractVector{UInt8}, secretOffset::Int, seed)
    # load two 64-bit words from input at inputOffset and inputOffset+8
    d1 = loadu64(input, inputOffset + 1)
    d2 = loadu64(input, inputOffset + 9)
    # load two 64-bit secret words starting at secretOffset
    s1 = loadu64(secret, secretOffset + 1)
    s2 = loadu64(secret, secretOffset + 9)

    mulResult = UInt128(d1 ⊻ (s1 + seed)) * UInt128(d2 ⊻ (s2 - seed))
    lowerhalf, higherhalf = lowerhigher(mulResult)
    return lowerhalf ⊻ higherhalf
end

# (Removed unused mixStep_words; mixStep_ptr covers required cases.)
@inline function XXH3_64_17to128(self)
    (; input, inputLength, secret, seed) = self

    acc = UInt64(inputLength) * PRIME64_1
    numRounds = ((inputLength - 1) >> 5)
    @inbounds for i in numRounds:-1:0
        offsetStart = i * 16
        offsetEnd = inputLength - i * 16 - 16
        acc += mixStep_ptr(input, offsetStart, secret, i * 32, seed)
        acc += mixStep_ptr(input, offsetEnd, secret, i * 32 + 16, seed)
    end
    return _avalanche(acc)
end

@inline function XXH3_64_129to240(self)
    (; input, inputLength, secret, seed) = self

    acc = UInt64(inputLength) * PRIME64_1
    numChunks = inputLength >> 4
    @inbounds for i = 0:7
        acc += mixStep_ptr(input, i*16, secret, i * 16, seed)
    end
    acc = _avalanche(acc)
    @inbounds for i = 8:numChunks-1
        acc += mixStep_ptr(input, i*16, secret, (i - 8) * 16 + 3, seed)
    end
    acc += mixStep_ptr(input, inputLength-16, secret, 119, seed)
    return _avalanche(acc)
end


@inline function accumulate!(acc, input::AbstractVector{UInt8}, stripeOffset::Int, secret::AbstractVector{UInt8}, secretOffset::Int)
    @inbounds begin
        # Preload 8 secret words for this stripe
        s1 = loadu64(secret, secretOffset + 1)
        s2 = loadu64(secret, secretOffset + 9)
        s3 = loadu64(secret, secretOffset + 17)
        s4 = loadu64(secret, secretOffset + 25)
        s5 = loadu64(secret, secretOffset + 33)
        s6 = loadu64(secret, secretOffset + 41)
        s7 = loadu64(secret, secretOffset + 49)
        s8 = loadu64(secret, secretOffset + 57)

        # Load 8 input words of the stripe
        d1 = loadu64(input, stripeOffset + 1)
        d2 = loadu64(input, stripeOffset + 9)
        d3 = loadu64(input, stripeOffset + 17)
        d4 = loadu64(input, stripeOffset + 25)
        d5 = loadu64(input, stripeOffset + 33)
        d6 = loadu64(input, stripeOffset + 41)
        d7 = loadu64(input, stripeOffset + 49)
        d8 = loadu64(input, stripeOffset + 57)

        # Process 8 lanes
        v1 = d1 ⊻ s1; lo, hi = lowerhigher(v1); acc[((1-1)⊻1)+1] += d1; acc[1] += UInt64(lo) * UInt64(hi)
        v2 = d2 ⊻ s2; lo, hi = lowerhigher(v2); acc[((2-1)⊻1)+1] += d2; acc[2] += UInt64(lo) * UInt64(hi)
        v3 = d3 ⊻ s3; lo, hi = lowerhigher(v3); acc[((3-1)⊻1)+1] += d3; acc[3] += UInt64(lo) * UInt64(hi)
        v4 = d4 ⊻ s4; lo, hi = lowerhigher(v4); acc[((4-1)⊻1)+1] += d4; acc[4] += UInt64(lo) * UInt64(hi)
        v5 = d5 ⊻ s5; lo, hi = lowerhigher(v5); acc[((5-1)⊻1)+1] += d5; acc[5] += UInt64(lo) * UInt64(hi)
        v6 = d6 ⊻ s6; lo, hi = lowerhigher(v6); acc[((6-1)⊻1)+1] += d6; acc[6] += UInt64(lo) * UInt64(hi)
        v7 = d7 ⊻ s7; lo, hi = lowerhigher(v7); acc[((7-1)⊻1)+1] += d7; acc[7] += UInt64(lo) * UInt64(hi)
        v8 = d8 ⊻ s8; lo, hi = lowerhigher(v8); acc[((8-1)⊻1)+1] += d8; acc[8] += UInt64(lo) * UInt64(hi)
    end
    return acc
end

# Aligned accumulate using 64-bit view; stripeOffsetWords is 1-based word index
@inline function accumulate_words!(acc, input64::AbstractVector{UInt64}, stripeOffsetWords::Int, secret::AbstractVector{UInt8}, secretOffset::Int)
    @inbounds begin
        s1 = loadu64(secret, secretOffset + 1)
        s2 = loadu64(secret, secretOffset + 9)
        s3 = loadu64(secret, secretOffset + 17)
        s4 = loadu64(secret, secretOffset + 25)
        s5 = loadu64(secret, secretOffset + 33)
        s6 = loadu64(secret, secretOffset + 41)
        s7 = loadu64(secret, secretOffset + 49)
        s8 = loadu64(secret, secretOffset + 57)

        w = stripeOffsetWords
        d1 = input64[w];     v1 = d1 ⊻ s1; lo, hi = lowerhigher(v1); acc[((1-1)⊻1)+1] += d1; acc[1] += UInt64(lo) * UInt64(hi)
        d2 = input64[w+1];   v2 = d2 ⊻ s2; lo, hi = lowerhigher(v2); acc[((2-1)⊻1)+1] += d2; acc[2] += UInt64(lo) * UInt64(hi)
        d3 = input64[w+2];   v3 = d3 ⊻ s3; lo, hi = lowerhigher(v3); acc[((3-1)⊻1)+1] += d3; acc[3] += UInt64(lo) * UInt64(hi)
        d4 = input64[w+3];   v4 = d4 ⊻ s4; lo, hi = lowerhigher(v4); acc[((4-1)⊻1)+1] += d4; acc[4] += UInt64(lo) * UInt64(hi)
        d5 = input64[w+4];   v5 = d5 ⊻ s5; lo, hi = lowerhigher(v5); acc[((5-1)⊻1)+1] += d5; acc[5] += UInt64(lo) * UInt64(hi)
        d6 = input64[w+5];   v6 = d6 ⊻ s6; lo, hi = lowerhigher(v6); acc[((6-1)⊻1)+1] += d6; acc[6] += UInt64(lo) * UInt64(hi)
        d7 = input64[w+6];   v7 = d7 ⊻ s7; lo, hi = lowerhigher(v7); acc[((7-1)⊻1)+1] += d7; acc[7] += UInt64(lo) * UInt64(hi)
        d8 = input64[w+7];   v8 = d8 ⊻ s8; lo, hi = lowerhigher(v8); acc[((8-1)⊻1)+1] += d8; acc[8] += UInt64(lo) * UInt64(hi)
    end
    return acc
end

@inline function round_scramble!(acc, secret)
    @inbounds begin
        base = length(secret) - 63
        s1 = loadu64(secret, base)
        s2 = loadu64(secret, base + 8)
        s3 = loadu64(secret, base + 16)
        s4 = loadu64(secret, base + 24)
        s5 = loadu64(secret, base + 32)
        s6 = loadu64(secret, base + 40)
        s7 = loadu64(secret, base + 48)
        s8 = loadu64(secret, base + 56)
        acc[1] = (acc[1] ⊻ (acc[1] >> 47)) ⊻ s1; acc[1] *= PRIME32_1
        acc[2] = (acc[2] ⊻ (acc[2] >> 47)) ⊻ s2; acc[2] *= PRIME32_1
        acc[3] = (acc[3] ⊻ (acc[3] >> 47)) ⊻ s3; acc[3] *= PRIME32_1
        acc[4] = (acc[4] ⊻ (acc[4] >> 47)) ⊻ s4; acc[4] *= PRIME32_1
        acc[5] = (acc[5] ⊻ (acc[5] >> 47)) ⊻ s5; acc[5] *= PRIME32_1
        acc[6] = (acc[6] ⊻ (acc[6] >> 47)) ⊻ s6; acc[6] *= PRIME32_1
        acc[7] = (acc[7] ⊻ (acc[7] >> 47)) ⊻ s7; acc[7] *= PRIME32_1
        acc[8] = (acc[8] ⊻ (acc[8] >> 47)) ⊻ s8; acc[8] *= PRIME32_1
    end
    return acc
end

@inline function round_accumulate_words!(acc, input64::AbstractVector{UInt64}, blockStartBytes::Int, secret, N)
    @inbounds begin
        base = (blockStartBytes >>> 3) + 1
        for n = 0:N-1
            accumulate_words!(acc, input64, base + n*8, secret, n * 8)
        end
    end
    return acc
end

# (SIMD path removed)

@inline function round_accumulate!(acc, input::AbstractVector{UInt8}, blockStart::Int, secret, N)
    @inbounds for n = 0:N-1
        accumulate!(acc, input, blockStart + n*64, secret, n * 8)
    end
    return acc
end

@inline function XXH3_64_large(self)
    (; input, inputLength, secret) = self
    acc = @MVector[
        PRIME32_3,
        PRIME64_1,
        PRIME64_2,
        PRIME64_3,
        PRIME64_4,
        PRIME32_2,
        PRIME64_5,
        PRIME32_1,
    ]
    secretLength = length(secret)
    stripesPerBlock = (secretLength - 64) ÷ 8
    blockSize = 64 * stripesPerBlock

    i = 1
    len8 = (inputLength >>> 3) << 3
    input64 = reinterpret(UInt64, @view input[1:len8])
    # all rounds except last one
    while i <= inputLength - blockSize
        round_accumulate_words!(acc, input64, i - 1, secret, stripesPerBlock)
        round_scramble!(acc, secret)
        i += blockSize
    end

    # last round
    len = inputLength - i
    nFullStripes = (len - 1) ÷ 64
    round_accumulate_words!(acc, input64, i - 1, secret, nFullStripes)

    # last 64-byte stripe
    accumulate_words!(acc, input64, ((inputLength - 64) >>> 3) + 1, secret, secretLength - 71)
    return finalMerge(acc, inputLength * PRIME64_1, secret, 11)
end

@inline function finalMerge(acc, initValue, secret, secretOffset)
    result = initValue
    @inbounds for i = 0:3
        s1 = loadu64(secret, secretOffset + 1 + i*16)
        s2 = loadu64(secret, secretOffset + 9 + i*16)
        mulResult = UInt128(acc[i*2+1] ⊻ s1) * UInt128(acc[i*2+2] ⊻ s2)
        lowerhalf, higherhalf = lowerhigher(mulResult)
        result += (lowerhalf ⊻ higherhalf)
    end
    return _avalanche(result)
end

struct XXHash64{T,S}
    input::T
    inputLength::Int
    seed::UInt64
    secret::S
end

function XXHash64(input::AbstractVector{UInt8}, seed = UInt64(0), secret = _ksecret_vec)
    return XXHash64(input, length(input), seed, secret)
end

"""
    xxh3_64(input::AbstractVector{UInt8}, seed=UInt64(0), secret=_ksecret_vec)

One-shot XXH3 64-bit hash.

- input: bytes to hash (e.g. `codeunits(str)`)
- seed: optional 64-bit seed
- secret: optional secret; defaults to the reference `_ksecret` bytes
"""
function xxh3_64(input::AbstractVector{UInt8}, seed = UInt64(0), secret = _ksecret_vec)
    Base.require_one_based_indexing(input, secret)
    inputLength = length(input)
    h64 = XXHash64(input, inputLength, seed, secret)
    if iszero(inputLength)
        return XXH3_64_empty(h64)
    elseif inputLength <= 3
        return XXH3_64_1to3(h64)
    elseif inputLength <= 8
        return XXH3_64_4to8(h64)
    elseif inputLength <= 16
        return XXH3_64_9to16(h64)
    elseif inputLength <= 128
        return XXH3_64_17to128(h64)
    elseif inputLength <= 240
        return XXH3_64_129to240(h64)
    else
        return XXH3_64_large(h64)
    end
end

xxh3_64(input::AbstractString, seed = UInt64(0), secret = _ksecret_vec) =
    xxh3_64(codeunits(input), seed, secret)

end
