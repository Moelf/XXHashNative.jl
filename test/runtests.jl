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
