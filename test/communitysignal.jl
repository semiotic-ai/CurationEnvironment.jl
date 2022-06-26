@testset "communitysignal" begin
    model = CurationEnvironment.CommunitySignal()

    @testset "payment" begin
        @testset "direct method" begin
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

    @testset "best_response" begin
        @testset "direct method" begin
            # # If v̂ = v, don't curate the subgraph
            # v = 100
            # v̂ = 100
            # τ = 0.0
            # x = 0.0
            # popt = CurationEnvironment.best_response(model, v, v̂, τ, x)
            # @test popt == 0.0

            # # The greater v̂ is than v, curate more
            # v = 100
            # v̂s = [100, 150, 200]
            # τ = 0.01
            # x = 0.0
            # popts = CurationEnvironment.best_response.(model, v, v̂s, τ, x)
            # @test issorted(popts)

            # The lesser v̂ is than v, burn more
            v = 100
            v̂s = [75, 50, 25]
            τ = 0.01
            x = 0.5
            popts = CurationEnvironment.best_response.(model, v, v̂s, τ, x)
            @test issorted(popts; rev=true)

            # The greater τ is, the less I will curate for the same v and v̂
            v = 100
            v̂ = 200
            x = 0.0
            τs = [0.0, 0.01, 0.1, 0.5]
            popts = CurationEnvironment.best_response.(model, v, v̂, τs, x)
            @test issorted(popts; rev=true)
        end

        @testset "domain model method" begin
            # If v̂ = v, don't curate the subgraph.
            # This test also ensures good behaviour when s.s = 0
            s = CurationEnvironment.Subgraph(1, 100, 0, 0.0)
            c = CurationEnvironment.Curator{1}(1, (100,), (0,), 100)
            popt = CurationEnvironment.best_response(model, c, s)
            @test popt == 0.0
        end
    end

    @testset "step" begin
        # If the v̂ = v, the state of the network remains the same.
        c = CurationEnvironment.Curator{1}(1, (100.0,), (0.0,), 100.0)
        s = CurationEnvironment.Subgraph(1, 100.0, 0.0, 0.0)
        π = CurationEnvironment.best_response
        nc, ns = CurationEnvironment.step(model, π, c, s)
        @test c == nc
        @test s == ns

        # If v̂ > v, we stake some tokens on the subgraph, which causes σ to decrease
        c = CurationEnvironment.Curator{1}(1, (200.0,), (0.0,), 100.0)
        s = CurationEnvironment.Subgraph(1, 100.0, 0.0, 0.0)
        π = CurationEnvironment.best_response
        nc, ns = CurationEnvironment.step(model, π, c, s)
        @test nc.σ < c.σ
        @test nc.ses[1] > c.ses[1]
        @test ns.v > s.v

        # If v̂ > v, we burn some tokens on the subgraph, which causes σ to decrease
        c = CurationEnvironment.Curator{1}(1, (0.0,), (1.0,), 100.0)
        s = CurationEnvironment.Subgraph(1, 100.0, 100.0, 0.0)
        π = CurationEnvironment.best_response
        nc, ns = CurationEnvironment.step(model, π, c, s)
        @test nc.σ > c.σ
        @test nc.ses[1] < c.ses[1]
        @test ns.v < s.v
    end
end
