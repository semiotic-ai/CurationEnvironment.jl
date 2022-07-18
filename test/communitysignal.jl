@testset "communitysignal" begin
    model = CurationEnvironment.CommunitySignal()
    @testset "best_response" begin
        @testset "direct method" begin
            # If v̂ = v, don't curate the subgraph
            v = 100
            v̂ = 100
            τ = 0.0
            x = 0.0
            σ = 1000.0
            popt = CurationEnvironment.best_response(model, v, v̂, τ, x, σ)
            @test popt == 0.0

            # The greater v̂ is than v, curate more
            v = 100
            v̂s = [100, 150, 200]
            τ = 0.01
            x = 0.0
            σ = 1000.0
            popts = CurationEnvironment.best_response.(model, v, v̂s, τ, x, σ)
            @test issorted(popts)

            # The lesser v̂ is than v, burn more
            v = 100
            v̂s = [75, 50, 25]
            τ = 0.01
            x = 0.5
            σ = 1000.0
            popts = CurationEnvironment.best_response.(model, v, v̂s, τ, x, σ)
            @test issorted(popts; rev=true)

            # The greater τ is, the less I will curate for the same v and v̂
            v = 100
            v̂ = 200
            x = 0.0
            τs = [0.0, 0.01, 0.1, 0.5]
            σ = 1000.0
            popts = CurationEnvironment.best_response.(model, v, v̂, τs, x, σ)
            @test issorted(popts; rev=true)

            # Don't try to stake more than you have.
            v = 100
            v̂ = 1000
            τ = 0.0
            x = 0.0
            σ = 5
            popt = CurationEnvironment.best_response(model, v, v̂, τ, x, σ)
            @test popt == 5.0
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
