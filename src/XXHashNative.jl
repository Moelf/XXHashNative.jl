module XXHashNative
# Julia re-write
using StaticArrays: @MVector, @SVector

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

const Prime1 = 0x9E3779B185EBCA87
const Prime2 = 0xC2B2AE3D27D4EB4F
const Prime3 = 0x165667B19E3779F9
const Prime4 = 0x85EBCA77C2B2AE63
const Prime5 = 0x27D4EB2F165667C5
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

function ifb32(bytes, offset = 0)
    reinterpret(UInt32, @view bytes[offset:offset+3]) |> only
end
function ifb64(bytes, offset = 0)
    reinterpret(UInt64, @view bytes[offset:offset+7]) |> only
end

function lowerhigher(x::UInt128)
    hi = (x >> 64) % UInt64
    lo = x % UInt64
    return (lo, hi)
end

function lowerhigher(x::UInt64)
    hi = (x >> 32) % UInt32
    lo = x % UInt32
    return (lo, hi)
end

function _avalanche(h::UInt64)
    h = (h ⊻ (h >> 37)) * PRIME_MX1
    h = h ⊻ (h >> 32)
    return h
end

function _avalanche64(h::UInt64)
    h = (h ⊻ (h >> 33)) * Prime2
    h = (h ⊻ (h >> 29)) * Prime3
    return h ⊻ (h >> 32)
end

function XXH3_64_empty(self)
    return _avalanche64(self.seed ⊻ ifb64(self.secret, 56 + 1) ⊻ ifb64(self.secret, 64 + 1))
end

function XXH3_64_1to3(self)
    (; input, inputLength, secret, seed) = self

    b1 = UInt32(input[end])
    b2 = UInt32(inputLength) << 8
    b3 = UInt32(input[begin]) << 16
    b4 = UInt32(input[inputLength>>1+1]) << 24
    combined = b1 | b2 | b3 | b4
    i1 = UInt64(ifb32(secret, 1) ⊻ ifb32(secret, 4 + 1)) + seed
    value = i1 ⊻ combined
    return _avalanche64(value)
end

function XXH3_64_4to8(self)
    (; input, inputLength, secret, seed) = self

    inputFirst = ifb32(input, 1)
    inputLast = ifb32(input, inputLength - 4 + 1)

    i1 = UInt64(bswap(UInt32(seed >> 32))) << 32
    modifiedSeed = seed ⊻ i1
    secretWords = reinterpret(UInt64, @view secret[8+1:24])
    combined = UInt64(inputLast) | (UInt64(inputFirst) << 32)

    value = ((secretWords[1] ⊻ secretWords[2]) - modifiedSeed) ⊻ combined
    value ⊻= ((value << 49) | (value >> 15)) ⊻ ((value << 24) | (value >> 40))
    value = value * PRIME_MX2
    value = value ⊻ ((value >> 35) + inputLength)
    value = value * PRIME_MX2
    value = value ⊻ (value >> 28)

    return value
end


function XXH3_64_9to16(self)
    (; input, inputLength, secret, seed) = self

    inputFirst = ifb64(input, 1)
    inputLast = ifb64(input, inputLength - 8 + 1)

    secretWords = reinterpret(UInt64, @view secret[24+1:56])
    low = ((secretWords[1] ⊻ secretWords[2]) + seed) ⊻ inputFirst
    high = ((secretWords[3] ⊻ secretWords[4]) - seed) ⊻ inputLast

    mulResult = UInt128(low) * UInt128(high)
    lowerhalf, higherhalf = lowerhigher(mulResult)
    value = inputLength + bswap(low) + high + (lowerhalf ⊻ higherhalf)

    return _avalanche(value)
end

function mixStep(data, secret, secretOffset, seed)
    dataWords = reinterpret(UInt64, data)
    secretWords = reinterpret(UInt64, @view secret[secretOffset+1:secretOffset+16])

    mulResult =
        UInt128(dataWords[1] ⊻ (secretWords[1] + seed)) *
        UInt128(dataWords[2] ⊻ (secretWords[2] - seed))
    lowerhalf, higherhalf = lowerhigher(mulResult)
    return lowerhalf ⊻ higherhalf

end
function XXH3_64_17to128(self)
    (; input, inputLength, secret, seed) = self

    acc = UInt64(inputLength) * PRIME64_1
    numRounds = ((inputLength - 1) >> 5) + 1
    # need signed to break the while loop
    i = Int(numRounds - 1)
    while i >= 0
        offsetStart = i * 16
        offsetEnd = inputLength - i * 16 - 16
        acc += mixStep(input[offsetStart+1:offsetStart+16], secret, i * 32, seed)
        acc += mixStep(input[offsetEnd+1:offsetEnd+16], secret, i * 32 + 16, seed)
        i -= 1
    end
    return _avalanche(acc)
end

function XXH3_64_129to240(self)
    (; input, inputLength, secret, seed) = self

    acc = UInt64(inputLength) * PRIME64_1
    numChunks = inputLength >> 4
    for i = 0:7
        acc += mixStep(input[i*16+1:i*16+16], secret, i * 16, seed)
    end
    acc = _avalanche(acc)
    for i = 8:numChunks-1
        acc += mixStep(input[i*16+1:i*16+16], secret, (i - 8) * 16 + 3, seed)
    end
    acc += mixStep(input[inputLength-16+1:inputLength], secret, 119, seed)
    return _avalanche(acc)
end


function accumulate!(acc, stripe, secret, secretOffset)
    secretWords = reinterpret(UInt64, @view secret[secretOffset+1:secretOffset+64])
    for i = 0:7
        value::UInt64 = stripe[i+1] ⊻ secretWords[i+1]
        acc[i⊻1+1] = acc[i⊻1+1] + stripe[i+1]
        lowerhalf, higherhalf = lowerhigher(value)
        acc[i+1] = acc[i+1] + UInt64(lowerhalf) * UInt64(higherhalf)
    end
    return acc
end

function round_scramble!(acc, secret)
    secretWords = reinterpret(UInt64, @view secret[end-63:end])
    for i = 1:8
        acc[i] = acc[i] ⊻ (acc[i] >> 47)
        acc[i] = acc[i] ⊻ secretWords[i]
        acc[i] = acc[i] * PRIME32_1
    end
    return acc
end

function round_accumulate!(acc, block, secret, N)
    for n = 0:N-1
        _stripe = @view block[n*64+1:n*64+64]
        stripe = reinterpret(UInt64, _stripe)
        accumulate!(acc, stripe, secret, n * 8)
    end
    return acc
end

function XXH3_64_large(self)
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
    # all rounds except last one
    while i <= inputLength - blockSize
        round_accumulate!(acc, @view(input[i:i+blockSize-1]), secret, stripesPerBlock)
        round_scramble!(acc, secret)
        i += blockSize
    end

    # last round
    last_block = @view input[i:end]
    len = inputLength - i
    nFullStripes = (len - 1) ÷ 64
    round_accumulate!(acc, last_block, secret, nFullStripes)

    buf_end = reinterpret(UInt64, @view input[end-63:end])
    accumulate!(acc, buf_end, secret, secretLength - 71)
    return finalMerge(acc, inputLength * PRIME64_1, secret, 11)
end

function finalMerge(acc, initValue, secret, secretOffset)
    secretWords = reinterpret(UInt64, @view secret[secretOffset+1:secretOffset+64])
    result = initValue
    for i = 0:3
        mulResult =
            UInt128(acc[i*2+1] ⊻ secretWords[i*2+1]) *
            UInt128(acc[i*2+1+1] ⊻ secretWords[i*2+1+1])
        lowerhalf, higherhalf = lowerhigher(mulResult)
        result = result + (lowerhalf ⊻ higherhalf)
    end
    return _avalanche(result)
end

struct XXHash64{T,S}
    input::T
    inputLength::Int64
    seed::UInt64
    secret::S
end

function XXHash64(input::AbstractVector{UInt8}, seed = UInt64(0), secret = _ksecret)
    return XXHash64(input, length(input), seed, secret)
end

"""
    xxh3_64(ary::AbstractVector{UInt8}, seed=UInt64(0), secret=_ksecret)
"""
function xxh3_64(input::AbstractVector{UInt8}, seed = UInt64(0), secret = _ksecret)
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

xxh3_64(input::AbstractString, seed = UInt64(0), secret = _ksecret) =
    xxh3_64(codeunits(input), seed, secret)

end
