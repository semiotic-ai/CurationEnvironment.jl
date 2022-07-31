@testset "subgraph" begin
    @testset "Subgraph" begin
        @testset "constructors" begin
            s1 = Subgraph(1, 100.0, 1.0, 0.05)
            s2 = Subgraph{Int64,Float64}(1, 100.0, 1.0, 0.05)
            @test s1 == s2

            # If id < 1, should throw an ArgumentError
            @test_throws ArgumentError CurationEnvironment.Subgraph(0, 100, 1, 0)
        end

        @testset "accessors" begin
            s = Subgraph(1, 100.0, 1.0, 0.05)

            s = v(s, 200.0)
            @test v(s) == 200.0

            s = ς(s, 2.0)
            @test ς(s) == 2.0

            @test id(s) == 1

            s = τ(s, 0.01)
            @test τ(s) == 0.01
        end
    end
end
