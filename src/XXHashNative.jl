module XXHashNative
# Julia re-write
using OffsetArrays: OffsetArray as OA
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

const MaxBufferSize = 32
const Prime1 = 0x9E3779B185EBCA87
const Prime2 = 0xC2B2AE3D27D4EB4F
const Prime3 = 0x165667B19E3779F9
const Prime4 = 0x85EBCA77C2B2AE63
const Prime5 = 0x27D4EB2F165667C5
const _ksecret = OA(@SVector[
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
    ], -1)

const _SECRET_DEFAULT_SIZE = 192
const _SECRET_CONSUME_RATE = 8
const _STRIPE_LEN = 64

function ifb32(bytes, offset=0)
    reinterpret(UInt32, bytes[offset:offset+3]) |> only
end
function ifb64(bytes, offset=0)
    reinterpret(UInt64, bytes[offset:offset+7]) |> only
end

mutable struct XXHash64
    states
    input
    inputLength
    _seed
    _secret
end

function _avalanche(h)
    h = (h ⊻ (h >> 37)) * PRIME_MX1
    h = h ⊻ (h >> 32)
    return h
end

function _avalanche64(h)
    h = (h ⊻ (h >> 33)) * Prime2
    h = (h ⊻ (h >> 29)) * Prime3
    return h ⊻ (h >> 32)
end

function XXH3_64_empty(self)
    # Used by intdigest() if 0 bytes have been added
    return _avalanche64(
        self._seed ⊻ ifb64(self._secret, 56) ⊻ ifb64(self._secret, 64)
    )
end

function XXH3_64_1to3(self)
    # Used by intdigest() if 1-3 bytes have been added
    L = self.inputLength
    b1 = UInt32(self.input[end])
    b2 = UInt32(L) << 8
    b3 = UInt32(self.input[0]) << 16
    b4 = UInt32(self.input[self.inputLength>>1]) << 24
    combined = b1 | b2 | b3 | b4
    i1 = UInt64(ifb32(self._secret) ⊻ ifb32(self._secret, 4)) + self._seed
    value = i1 ⊻ combined
    return _avalanche64(value)
end

function XXH3_64_4to8(self)
    # Used by intdigest() if 1-3 bytes have been added
    inputFirst = ifb32(self.input)
    inputLast = ifb32(self.input, self.inputLength - 4)

    i1 = UInt64(bswap(UInt32(self._seed >> 32))) << 32
    modifiedSeed = self._seed ⊻ i1
    secretWords = reinterpret(UInt64, self._secret[8:23])
    combined = UInt64(inputLast) | (UInt64(inputFirst) << 32)

    value = ((secretWords[1] ⊻ secretWords[2]) - modifiedSeed) ⊻ combined
    value ⊻= ((value << 49) | (value >> 15)) ⊻ ((value << 24) | (value >> 40))
    value = value * PRIME_MX2
    value = value ⊻ ((value >> 35) + self.inputLength)
    value = value * PRIME_MX2
    value = value ⊻ (value >> 28)

    return value
end


function XXH3_64_9to16(self)
    # Used by intdigest() if 1-3 bytes have been added
    inputFirst = ifb64(self.input)
    inputLast = ifb64(self.input, self.inputLength - 8)

    secretWords = reinterpret(UInt64, self._secret[24:55])
    low = ((secretWords[1] ⊻ secretWords[2]) + self._seed) ⊻ inputFirst
    high = ((secretWords[3] ⊻ secretWords[4]) - self._seed) ⊻ inputLast

    mulResult = UInt128(low) * UInt128(high)
    lowerhalf, higherhalf = reinterpret(NTuple{2,UInt64}, mulResult)
    value = self.inputLength + bswap(low) + high + (lowerhalf ⊻ higherhalf)

    return _avalanche(value)
end

function mixStep(data, secret, secretOffset, seed)
    dataWords = reinterpret(UInt64, data)
    secretWords = reinterpret(UInt64, secret[secretOffset:secretOffset+15])

    mulResult = UInt128(dataWords[1] ⊻ (secretWords[1] + seed)) *
                UInt128(dataWords[2] ⊻ (secretWords[2] - seed))
    lowerhalf, higherhalf = reinterpret(NTuple{2,UInt64}, mulResult)
    return lowerhalf ⊻ higherhalf

end
function XXH3_64_17to128(self)
    acc = UInt64(self.inputLength) * PRIME64_1
    numRounds = ((self.inputLength - 1) >> 5) + 1
    i = Int(numRounds - 1)
    seed = self._seed
    input = self.input
    secret = self._secret
    while i >= 0
        offsetStart = i * 16
        offsetEnd = self.inputLength - i * 16 - 16
        acc += mixStep(input[offsetStart:offsetStart+15], secret, i * 32, seed)
        acc += mixStep(input[offsetEnd:offsetEnd+15], secret, i * 32 + 16, seed)
        i -= 1
    end
    return _avalanche(acc)
end

function XXH3_64_129to240(self)
    inputLength = self.inputLength
    acc = UInt64(inputLength) * PRIME64_1
    numChunks = inputLength >> 4
    secret = self._secret
    seed = self._seed
    input = self.input
    for i in 0:7
        acc += mixStep(input[i*16:i*16+16-1], secret, i * 16, seed)
    end
    acc = _avalanche(acc)
    for i in 8:numChunks-1
        acc += mixStep(input[i*16:i*16+16-1], secret, (i - 8) * 16 + 3, seed)
    end
    acc += mixStep(input[inputLength-16:inputLength-1], secret, 119, seed)
    return _avalanche(acc)
end


function accumulate!(acc, stripe, secret, secretOffset)
    secretWords = OA(reinterpret(UInt64, secret[secretOffset:secretOffset+64-1]), -1)
    for i = 0:7
        value = stripe[i] ⊻ secretWords[i]
        acc[i⊻1] = acc[i⊻1] + stripe[i]
        lowerhalf, higherhalf = reinterpret(NTuple{2,UInt32}, value)
        acc[i] = acc[i] + UInt64(lowerhalf) * UInt64(higherhalf)
    end
end

function scramble!(acc, secret)
    secretWords = OA(reinterpret(UInt64, last(secret, 64)), -1)
    for i = 0:7
        acc[i] = acc[i] ⊻ (acc[i] >> 47)
        acc[i] = acc[i] ⊻ secretWords[i]
        acc[i] = acc[i] * PRIME32_1
    end
end

function XXH3_64_large(self)
    acc = OA(@MVector[PRIME32_3, PRIME64_1, PRIME64_2, PRIME64_3,
            PRIME64_4, PRIME32_2, PRIME64_5, PRIME32_1], -1)
    secretLength = length(self._secret)
    stripesPerBlock = (secretLength - 64) ÷ 8
    blockSize = 64 * stripesPerBlock
    secret = self._secret


    blocks = collect(Iterators.partition(self.input, blockSize))
    local last_stripe
    for _block in @view blocks[begin:end-1]
        block = OA(_block, -1)
        for n = 0:stripesPerBlock-1
            last_stripe = block[n*64:n*64+64-1]
            stripe = OA(reinterpret(UInt64, last_stripe), -1)
            accumulate!(acc, stripe, secret, n * 8)
        end
        scramble!(acc, secret)
    end

    # lastround
    _block = last(blocks)
    block = OA(_block, -1)
    len = length(block)
    nFullStripes = (len - 1) ÷ 64
    for n in 0:nFullStripes-1
        _stripe = block[n*64:n*64+64-1]
        stripe = OA(reinterpret(UInt64, _stripe), -1)
        accumulate!(acc, stripe, secret, n * 8)
    end
    buf_end = last(vcat(last_stripe, _block), 64)

    buf_end = reinterpret(UInt64, last(self.input, 64))
    accumulate!(acc, OA(buf_end, -1), secret, secretLength - 71)
    return finalMerge(acc, length(self.input) * PRIME64_1, secret, 11)
end

function finalMerge(acc, initValue, secret, secretOffset)
    secretWords = OA(reinterpret(UInt64, secret[secretOffset:secretOffset+64-1]), -1)
    result = initValue
    for i in 0:3
        mulResult = UInt128(acc[i*2] ⊻ secretWords[i*2]) *
                    UInt128(acc[i*2+1] ⊻ secretWords[i*2+1])
        lowerhalf, higherhalf = reinterpret(NTuple{2,UInt64}, mulResult)
        result = result + (lowerhalf ⊻ higherhalf)
    end
    return _avalanche(result)
end


function XXHash64(_data::AbstractVector{UInt8}, seed=UInt64(0), secret=_ksecret)
    states = OA(
        UInt64[
            seed+Prime1+Prime2,
            seed+Prime2,
            seed,
            seed-Prime1
        ],
        -1)

    input = OA(_data, -1)

    return XXHash64(states, input, UInt64(length(input)), seed, secret)
    error()
end

end
