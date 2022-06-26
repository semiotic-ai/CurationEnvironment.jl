@testset "domainmodel" begin
    @testset "Curator" begin
        # If id < 1, should throw an ArgumentError
        @test_throws ArgumentError CurationEnvironment.Curator{1}(0, (100,), (0,), 100.0)

        # If σ < 0, should throw an ArgumentError
        @test_throws ArgumentError CurationEnvironment.Curator{1}(1, (100,), (0,), -100.0)

        # If only provided one number for v̂s and for xs, repeat that number to fill a tuple.
        c = CurationEnvironment.Curator{5}(1, 100, 0, 100.0)
        @test length(c.ses) == 5
    end

    @testset "Subgraph" begin
        # If id < 1, should throw an ArgumentError
        @test_throws ArgumentError CurationEnvironment.Subgraph(0, 100, 1, 0)

        # If v < 0, should throw an ArgumentError
        @test_throws ArgumentError CurationEnvironment.Subgraph(1, -1, 1, 0)

        # If s < 0, should throw an ArgumentError
        @test_throws ArgumentError CurationEnvironment.Subgraph(1, 100, -1, 0)

        # If τ < 0, should throw an ArgumentError
        @test_throws ArgumentError CurationEnvironment.Subgraph(1, 100, 1, -1)
    end
end
