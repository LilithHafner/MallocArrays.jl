using MallocArrays
using Test
using Aqua

@testset "Code quality (Aqua.jl)" begin
    Aqua.test_all(MallocArrays, deps_compat=false)
    Aqua.test_deps_compat(MallocArrays, check_extras=false)
end

@testset "Basics" begin
    x = malloc(Int, 10)
    @test x isa AbstractVector{Int}
    @test x isa MallocArray

    x .= 1:10
    @test x == 1:10

    @test_throws BoundsError x[11]
    @test_throws BoundsError x[0]
    @test_throws BoundsError x[0] = 0
    @test_throws BoundsError x[11] = 0

    @test free(x) === nothing

    y = malloc(Complex{Float64}, 4, 10)
    @test length(y) == 40
    @test size(y) == (4, 10)
    @test y isa AbstractMatrix{Complex{Float64}}
    @test y isa MallocArray

    fill!(y, im)
    @test all(z -> z === 1.0im, y)
    @test count(!iszero, y) == 40
    y[4, 10] = 0
    @test y[40] == y[4, 10] == 0
    @test_throws BoundsError y[41]
    @test_throws BoundsError y[10, 4]

    @test free(y) === nothing

    @test_throws ArgumentError malloc(Vector{Int}, 10)
end

function f(x, y)
    z = malloc(Int, x)
    z .= y
    res = sum(z)
    free(z)
    res
end
@testset "Allocations" begin
    @test f(10, 1:10) == 55
    @test 0 == @allocated f(10, 1:10)
end

@testset "Invalid dimensions" begin
    @test_throws ArgumentError("invalid malloc dimensions") malloc(Int, -10, 10, 0)
    @test_throws ArgumentError("invalid malloc dimensions") malloc(Int, 1000000, 1000000, 1000000, 1000000)
    @test_throws ArgumentError("invalid malloc dimensions") malloc(Nothing, 1000000, 1000000, 1000000, 1000000)
    @test_throws ArgumentError("invalid malloc dimensions") malloc(Int, 2^(Sys.WORD_SIZE-4))
    @test_throws ArgumentError("invalid malloc dimensions") malloc(Int, 2^(Sys.WORD_SIZE-2)-1)
    @test_throws ArgumentError("invalid malloc dimensions") malloc(Int, 2^(Sys.WORD_SIZE-3)-1)
    @test_throws ArgumentError("invalid malloc dimensions") malloc(Int, 2^(Sys.WORD_SIZE-2))
    @test_throws ArgumentError("invalid malloc dimensions") malloc(Int, 2^(Sys.WORD_SIZE-3))
    @test_throws ArgumentError("invalid malloc dimensions") malloc(UInt128, 2^3, 2^(Sys.WORD_SIZE-5))
    @test_throws OutOfMemoryError() malloc(Int, 2^(Sys.WORD_SIZE-5))
end
