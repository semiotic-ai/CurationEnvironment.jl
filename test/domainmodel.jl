@testset "domainmodel" begin
    @testset "Curator" begin
        # If id < 1, should throw an ArgumentError
        @test_throws ArgumentError CurationEnvironment.Curator{1}(0, (100,), (0,), 100.0)

        # If σ < 0, should throw an ArgumentError
        @test_throws ArgumentError CurationEnvironment.Curator{1}(1, (100,), (0,), -100.0)

        # If only provided one number for v̂s and for xs, repeat that number to fill a tuple.
        c = CurationEnvironment.Curator{5}(1, 100, 0, 100.0)
        @test length(c.v̂s) == 5
    end

    @testset "Subgraph" begin
        # If id < 1, should throw an ArgumentError
        @test_throws ArgumentError CurationEnvironment.Subgraph(0, 100, 1, 0)
    end

    model = CurationEnvironment.CommunitySignal()
    @testset "payment" begin
        @testset "direct method" begin
            # Example
            τ = 0
            x = 1 / 3
            v = 300
            p = CurationEnvironment.payment(model, x, v, τ)
            @test p ≈ 150

            # Negative proportion, τ doesn't apply
            τ = 0
            x = -1 / 3
            v = 300
            p = CurationEnvironment.payment(model, x, v, τ)
            @test p ≈ -100

            # If τ = 0 and I want half of the shares, I'll need to double the signal.
            τ = 0
            x = 0.5
            v = 100
            p = CurationEnvironment.payment(model, x, v, τ)
            @test p == 100

            # For equivalent τ, the more proportion I want, the more I'll need to pay.
            τ = 0.01
            v = 100
            xs = [0.25, 0.5, 0.75]
            ps = CurationEnvironment.payment.(model, xs, v, τ)
            @test issorted(ps)

            # As τ increases, the amount I'll need to pay for the same proportion increases.
            x = 0.5
            v = 100
            τs = [0.0, 0.01, 0.1, 0.5]
            ps = CurationEnvironment.payment.(model, x, v, τs)
            @test issorted(ps)
        end

        @testset "domain model method" begin
            s = CurationEnvironment.Subgraph(1, 100, 1, 0.0)
            x = 0.5
            @test CurationEnvironment.payment(model, x, s) == 100
        end
    end

    @testset "equity_proportion" begin
        @testset "direct method" begin
            # If τ = 0, and I pay p, then I get back p / new market value
            τ = 0
            p = 100
            v = 100
            x = CurationEnvironment.equity_proportion(model, p, v, τ)
            @test x == 0.5

            # For equivalent τ, if I want greater proportion, I will need to pay more
            τ = 0.01
            v = 100
            ps = [50, 100, 150]
            xs = CurationEnvironment.equity_proportion.(model, ps, v, τ)
            @test issorted(xs)

            # As τ increases, the proportion I'll get for the same payment decreases.
            τs = [0.0, 0.01, 0.1, 0.5]
            v = 100
            p = 100
            xs = CurationEnvironment.equity_proportion.(model, p, v, τ)
            @test issorted(xs; rev=true)

            # Don't apply τ if buring tokens (p < 0)
            τs = [0.0, 0.01, 0.1, 0.5]
            v = 100
            p = -100
            xs = CurationEnvironment.equity_proportion.(model, p, v, τ)
            @test all(x -> x == xs[1], xs)
        end

        @testset "domain model method" begin
            s = CurationEnvironment.Subgraph(1, 100, 1, 0.0)
            p = 100
            @test CurationEnvironment.equity_proportion(model, p, s) == 0.5
        end
    end

    @testset "shares" begin
        @testset "direct method" begin
            # Example
            x = 1 / 3
            s = 300
            v = 300
            τ = 0.0
            ns = CurationEnvironment.shares(model, x, s, v, τ)
            @test ns ≈ 150

            # Negative proportion
            x = -1 / 3
            s = 300
            v = 300
            τ = 0.0
            ns = CurationEnvironment.shares(model, x, s, v, τ)
            @test ns ≈ -100

            # If you don't stake more, you don't mint new shares
            x = 0
            s = 100
            v = 100
            τ = 0.0
            ns = CurationEnvironment.shares(model, x, s, v, τ)
            @test ns == 0

            # As x increases, the number of shares minted increases
            xs = [0.25, 0.5, 0.75]
            s = 100
            v = 100
            τ = 0.0
            ns = CurationEnvironment.shares.(model, xs, s, v, τ)
            @test issorted(ns)

            # If s == 0, s -> p
            x = 0.5
            s = 0
            v = 100
            τ = 0.0
            ns = CurationEnvironment.shares(model, x, s, v, τ)
            @test ns == 100
        end

        @testset "domain model method" begin
            s = CurationEnvironment.Subgraph(1, 100, 1, 0.0)
            x = 0.0
            @test CurationEnvironment.shares(model, x, s) == 0
        end
    end

    @testset "curate" begin
        c = CurationEnvironment.Curator{1}(1, (110,), (0,), 100)
        s = CurationEnvironment.Subgraph(1, 100, 0, 0.0)
        p = 10

        c, s = CurationEnvironment.curate(model, p, c, s)
        @test c.ses[1] ≈ 10
        @test c.σ == 90
    end
end
