using Test
using XXHashNative: XXH3_64_empty, XXH3_64_1to3, XXH3_64_4to8, XXH3_64_9to16, XXH3_64_17to128, XXH3_64_129to240, XXH3_64_large, XXHash64

@testset "main" begin
    a = UInt8[]
    @test XXHash64(a) |> XXH3_64_empty == 0x2d06800538d394c2
    a = codeunits("ab")
    @test XXHash64(a) |> XXH3_64_1to3 == 0xa873719c24d5735c
    a = codeunits("abcde")
    @test XXHash64(a) |> XXH3_64_4to8 == 0x55c65158ee9e652d
    a = codeunits("abcdefghijklm")
    @test XXHash64(a) |> XXH3_64_9to16 == 0xd7b6fd946b75df4b
    a = codeunits("abcdefghijklmnopqrstuvwxyz")
    @test XXHash64(a) |> XXH3_64_17to128 == 0x810f9ca067fbb90c
    a = repeat(a, 8)
    @test XXHash64(a) |> XXH3_64_129to240 == 0x025ea73bba62f1fc
    a = repeat(a, 8)
    @test XXHash64(a) |> XXH3_64_large == 0xb56d7f174146570c
    @show @allocated XXHash64(a) |> XXH3_64_large
end
