using Test
using XXHashNative:
    XXH3_64_empty,
    XXH3_64_1to3,
    XXH3_64_4to8,
    XXH3_64_9to16,
    XXH3_64_17to128,
    XXH3_64_129to240,
    XXH3_64_large,
    XXHash64,
    xxh3_64,
    xxh64,
    XXH64State,
    update!,
    digest!

@testset "main" begin
    a = UInt8[]
    @test XXHash64(a) |> XXH3_64_empty == 0x2d06800538d394c2 == xxh3_64(a)
    a = codeunits("ab")
    @test XXHash64(a) |> XXH3_64_1to3 == 0xa873719c24d5735c == xxh3_64(a)
    a = codeunits("abcde")
    @test XXHash64(a) |> XXH3_64_4to8 == 0x55c65158ee9e652d == xxh3_64(a)
    a = codeunits("abcdefghijklm")
    @test XXHash64(a) |> XXH3_64_9to16 == 0xd7b6fd946b75df4b == xxh3_64(a)
    a = codeunits("abcdefghijklmnopqrstuvwxyz")
    @test XXHash64(a) |> XXH3_64_17to128 == 0x810f9ca067fbb90c == xxh3_64(a)
    a = repeat(a, 8)
    @test XXHash64(a) |> XXH3_64_129to240 == 0x025ea73bba62f1fc == xxh3_64(a)
    a = repeat(a, 8)
    @test XXHash64(a) |> XXH3_64_large == 0xb56d7f174146570c == xxh3_64(a)

    # when input smaller than 1024
    a = repeat("abcd", 100)
    @test xxh3_64(a) == 0xd4aa1a88b2c1f634

    # when input exactly 1024 long
    a = repeat("abcd", 256)
    @test xxh3_64(a) == 0xf90ef01af71cb18e

    a = repeat("abcd", 300)
    @test xxh3_64(a) == 0x33b975506e1b8a19
    @test xxh3_64(@view a[begin+4:1024+4]) == 0xf90ef01af71cb18e

    # when input exactly 2048 long
    a = repeat("abcd", 512)
    @test xxh3_64(a) == 0xb0ab971415c84a40

    a = repeat("abcd", 600)
    @test xxh3_64(a) == 0x816af0d37c98071f

end

@testset "xxh64" begin
    a = UInt8[]
    @test xxh64(a) == 0xef46db3751d8e999
    @test (XXH64State() |> digest!) == 0xef46db3751d8e999

    a = codeunits("ab")
    @test xxh64(a) == 0x65f708ca92d04a61
    @test (update!(XXH64State(), a) |> digest!) == 0x65f708ca92d04a61

    a = codeunits("abcde")
    @test xxh64(a) == 0x07e3670c0c8dc7eb
    @test (update!(XXH64State(), a) |> digest!) == 0x07e3670c0c8dc7eb

    a = codeunits("abcdefghijklm")
    @test xxh64(a) == 0x934adbc0ebc51325
    @test (update!(XXH64State(), a) |> digest!) == 0x934adbc0ebc51325

    a = codeunits("abcdefghijklmnopqrstuvwxyz")
    @test xxh64(a) == 0xcfe1f278fa89835c
    @test (update!(XXH64State(), a) |> digest!) == 0xcfe1f278fa89835c

    a = repeat(a, 8)
    @test xxh64(a) == 0xea1e82fca403bfab
    @test (update!(XXH64State(), a) |> digest!) == 0xea1e82fca403bfab

    a = repeat(a, 8)
    @test xxh64(a) == 0xe5f9c4bfb7047c1a
    @test (update!(XXH64State(), a) |> digest!) == 0xe5f9c4bfb7047c1a

    # when input smaller than 1024
    a = repeat("abcd", 100)
    @test xxh64(a) == 0xd43294be5ee68f13

    # when input exactly 1024 long
    a = repeat("abcd", 256)
    @test xxh64(a) == 0xf48efa325cbf8d2f

    a = repeat("abcd", 300)
    @test xxh64(a) == 0x8f7f794247c25ab7
    @test xxh64(@view codeunits(a)[begin+4:1024+4]) == 0xf48efa325cbf8d2f

    # when input exactly 2048 long
    a = repeat("abcd", 512)
    @test xxh64(a) == 0x06dc34a3a4b9b3e3

    a = repeat("abcd", 600)
    @test xxh64(a) == 0xa2779f6bd7a05689

end

@testset "xxh64 vs XXhash" begin
    import XXhash

    inputs = [
        "",
        "ab",
        "abcde",
        "abcdefghijklm",
        "abcdefghijklmnopqrstuvwxyz",
        repeat("abcdefghijklmnopqrstuvwxyz", 8),
        repeat("abcdefghijklmnopqrstuvwxyz", 64),
        repeat("abcd", 100),
        repeat("abcd", 256),
        repeat("abcd", 300),
        repeat("abcd", 512),
        repeat("abcd", 600),
    ]

    for input in inputs
        @test xxh64(input) == XXhash.xxh64(input)
    end

    # view into a byte array
    a = repeat("abcd", 300)
    v = collect(@view codeunits(a)[begin+4:1024+4])
    @test xxh64(v) == XXhash.xxh64(v)
end

@testset "xxh3_64 vs XXhash" begin
    import XXhash

    inputs = [
        "",
        "ab",
        "abcde",
        "abcdefghijklm",
        "abcdefghijklmnopqrstuvwxyz",
        repeat("abcdefghijklmnopqrstuvwxyz", 8),
        repeat("abcdefghijklmnopqrstuvwxyz", 64),
        repeat("abcd", 100),
        repeat("abcd", 256),
        repeat("abcd", 300),
        repeat("abcd", 512),
        repeat("abcd", 600),
    ]

    for input in inputs
        @test xxh3_64(input) == XXhash.xxh3_64(input)
    end

    # view into a byte array
    a = repeat("abcd", 300)
    v = collect(@view codeunits(a)[begin+4:1024+4])
    @test xxh3_64(v) == XXhash.xxh3_64(v)
end

@testset "xxh64 with seed vs XXhash" begin
    import XXhash

    inputs = [
        "",
        "ab",
        "abcde",
        "abcdefghijklm",
        "abcdefghijklmnopqrstuvwxyz",
        repeat("abcdefghijklmnopqrstuvwxyz", 8),
        repeat("abcdefghijklmnopqrstuvwxyz", 64),
        repeat("abcd", 300),
    ]

    for seed in [UInt64(1), UInt64(0xdeadbeef)], input in inputs
        @test xxh64(input, seed) == XXhash.xxh64(input, seed)
    end
end

@testset "xxh3_64 with seed vs XXhash" begin
    import XXhash

    # Each entry covers a distinct dispatch path in xxh3_64
    cases = [
        ("empty (0B)",       ""),
        ("1to3 (2B)",        "ab"),
        ("4to8 (5B)",        "abcde"),
        ("9to16 (13B)",      "abcdefghijklm"),
        ("17to128 (26B)",    "abcdefghijklmnopqrstuvwxyz"),
        ("129to240 (208B)",  repeat("abcdefghijklmnopqrstuvwxyz", 8)),
        ("large (1664B)",    repeat("abcdefghijklmnopqrstuvwxyz", 64)),
    ]

    seed = UInt64(0xdeadbeef)
    for (label, input) in cases
        @test xxh3_64(input, seed) == XXhash.xxh3_64(input, seed)
    end
end

@testset "xxh64 streaming multi-chunk" begin
    # Exercises the update! path where state.buffer_len > 0 on second call
    # (the fill-buffer-then-process branch, which had zero coverage)

    # Two chunks: small first (goes to buffer), then large (flushes buffer + processes blocks)
    for (a, b) in [
        ("hello",           repeat("x", 40)),   # 5 + 40: buffer flush at 32
        (repeat("a", 10),   repeat("b", 50)),   # 10 + 50
        (repeat("a", 31),   "x"),               # 31 + 1: exactly fills buffer
        (repeat("a", 20),   repeat("b", 100)),  # 20 + 100
    ]
        combined = a * b
        state = XXH64State()
        update!(state, a)
        update!(state, b)
        @test digest!(state) == xxh64(combined)
    end

    # Three chunks
    input = repeat("abcd", 300)
    bytes = codeunits(input)
    state = XXH64State()
    update!(state, bytes[1:10])
    update!(state, bytes[11:100])
    update!(state, bytes[101:end])
    @test digest!(state) == xxh64(input)
end
