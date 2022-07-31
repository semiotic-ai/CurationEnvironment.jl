@testset "curator" begin
    @testset "Curator" begin
        @testset "constructors" begin
            c1 = Curator{1}(1, (100.0,), (0.0,), 100.0)
            c2 = Curator(1, (100.0,), (0.0,), 100.0)
            c3 = Curator{1}(1, 100.0, 0.0, 100.0)
            c4 = Curator{1,Int64,Float64}(1, (100.0,), (0.0,), 100.0)
            @test c1 == c2 == c3 == c4

            # If id < 1, should throw an ArgumentError
            @test_throws ArgumentError CurationEnvironment.Curator{1}(
                0, (100.0,), (0.0,), 100.0
            )

            # If σ < 0, should throw an ArgumentError
            @test_throws ArgumentError CurationEnvironment.Curator{1}(
                1, (100.0,), (0.0,), -100.0
            )

            # If only provided one number for v̂s and for xs, repeat that number to fill a tuple.
            c = CurationEnvironment.Curator{5}(1, 100.0, 0.0, 100.0)
            @test length(c.v̂s) == 5
        end

        @testset "accessors" begin
            c = Curator{1,Int64,Float64}(1, (100.0,), (0.0,), 100.0)
            @test v̂s(c) == (100.0,)
            c = v̂s(c, 1, 200.0)
            @test v̂s(c, 1) == 200.0

            c = Curator{1,Int64,Float64}(1, (100.0,), (0.0,), 100.0)
            @test ςs(c) == (0.0,)
            c = ςs(c, 1, 1.0)
            @test ςs(c, 1) == 1.0

            c = Curator{1,Int64,Float64}(1, (100.0,), (0.0,), 100.0)
            c = σ(c, 1.0)
            @test σ(c) == 1.0

            c = Curator{1,Int64,Float64}(1, (100.0,), (0.0,), 100.0)
            @test id(c) == 1
        end
    end

    @testset "MinMaxCurator" begin
        @testset "constructors" begin
            c1 = MinMaxCurator{1,Int64,Float64}(1, (100.0,), (200.0,), (0.0,), 100.0)
            c = Curator{1,Int64,Float64}(1, (200.0,), (0.0,), 100.0)
            c2 = MinMaxCurator(c, (100.0,))
            @test c1 == c2
        end

        @testset "accessors" begin
            c = MinMaxCurator{1,Int64,Float64}(1, (100.0,), (200.0,), (0.0,), 100.0)
            @test v̂mins(c) == (100.0,)
            c = v̂mins(c, 1, 200.0)
            @test v̂mins(c, 1) == 200.0

            c = MinMaxCurator{1,Int64,Float64}(1, (100.0,), (200.0,), (0.0,), 100.0)
            @test v̂s(c) == (200.0,)
            c = v̂s(c, 1, 300.0)
            @test v̂s(c, 1) == 300.0

            c = MinMaxCurator{1,Int64,Float64}(1, (100.0,), (200.0,), (0.0,), 100.0)
            @test v̂maxs(c) == (200.0,)
            c = v̂maxs(c, 1, 300.0)
            @test v̂maxs(c, 1) == 300.0

            c = MinMaxCurator{1,Int64,Float64}(1, (100.0,), (200.0,), (0.0,), 100.0)
            @test ςs(c) == (0.0,)
            c = ςs(c, 1, 1.0)
            @test ςs(c, 1) == 1.0

            c = MinMaxCurator{1,Int64,Float64}(1, (100.0,), (200.0,), (0.0,), 100.0)
            c = σ(c, 1.0)
            @test σ(c) == 1.0

            c = MinMaxCurator{1,Int64,Float64}(1, (100.0,), (200.0,), (0.0,), 100.0)
            @test id(c) == 1
        end
    end
end
