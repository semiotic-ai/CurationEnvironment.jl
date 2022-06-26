@testset "domainmodel" begin
    @testset "Curator" begin
        # If id < 1, should throw an ArgumentError
        @test_throws ArgumentError CurationEnvironment.Curator{1}(0, (100,), (0,), 100.0)

        # If σ < 0, should throw an ArgumentError
        @test_throws ArgumentError CurationEnvironment.Curator{1}(1, (100,), (0,), -100.0)

        # If only provided one number for v̂s and for xs, repeat that number to fill a tuple.
        c = CurationEnvironment.Curator{5}(1, 100, 0, 100.0)
        @test length(c.xs) == 5
    end

    @testset "Subgraph" begin
        # If id < 1, should throw an ArgumentError
        @test_throws ArgumentError CurationEnvironment.Subgraph(0, 100, 0)

        # If v < 0, should throw an ArgumentError
        @test_throws ArgumentError CurationEnvironment.Subgraph(1, -1, 0)

        # If τ < 0, should throw an ArgumentError
        @test_throws ArgumentError CurationEnvironment.Subgraph(1, 100, -1)
    end

    @testset "payment" begin
        @testset "direct method" begin
            # If τ = 0 and I want half of the shares, I'll need to double the signal.
            τ = 0
            x = 0.5
            v = 100
            p = CurationEnvironment.payment(x, v, τ)
            @test p == 100

            # For equivalent τ, the more proportion I want, the more I'll need to pay.
            τ = 0.01
            v = 100
            xs = [0.25, 0.5, 0.75]
            ps = CurationEnvironment.payment.(xs, v, τ)
            @test issorted(ps)

            # As τ increases, the amount I'll need to pay for the same proportion increases.
            x = 0.5
            v = 100
            τs = [0.0, 0.01, 0.1, 0.5]
            ps = CurationEnvironment.payment.(x, v, τs)
            @test issorted(ps)
        end

        @testset "domain model method" begin
            s = CurationEnvironment.Subgraph(1, 100, 0.0)
            x = 0.5
            @test CurationEnvironment.payment(x, s) == 100
        end
    end

    @testset "equity_proportion" begin
        @testset "direct method" begin
            # If τ = 0, and I pay p, then I get back p / new market value
            τ = 0
            p = 100
            v = 100
            x = CurationEnvironment.equity_proportion(p, v, τ)
            @test x == 0.5

            # For equivalent τ, if I want greater proportion, I will need to pay more
            τ = 0.01
            v = 100
            ps = [50, 100, 150]
            xs = CurationEnvironment.equity_proportion.(ps, v, τ)
            @test issorted(xs)

            # As τ increases, the proportion I'll get for the same payment decreases.
            τs = [0.0, 0.01, 0.1, 0.5]
            v = 100
            p = 100
            xs = CurationEnvironment.equity_proportion.(p, v, τ)
            @test issorted(xs; rev=true)
        end

        @testset "domain model method" begin
            s = CurationEnvironment.Subgraph(1, 100, 0.0)
            p = 100
            @test CurationEnvironment.equity_proportion(p, s) == 0.5
        end
    end
end
