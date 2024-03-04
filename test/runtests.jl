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
    xxh3_64

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
    @show @allocated XXHash64(a) |> XXH3_64_large

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
