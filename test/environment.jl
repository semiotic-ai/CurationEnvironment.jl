@testset "environment" begin
    @testset "step" begin
        # If the v̂ = v, the state of the network remains the same.
        c = CurationEnvironment.Curator{1}(1, (100.0,), (0.0,), 100.0)
        s = CurationEnvironment.Subgraph(1, 100.0, 0.0)
        π = CurationEnvironment.best_response
        nc, ns = CurationEnvironment.step(π, c, s)
        @test c == nc
        @test s == ns

        # If v̂ > v, we stake some tokens on the subgraph, which causes σ to decrease
        c = CurationEnvironment.Curator{1}(1, (200.0,), (0.0,), 100.0)
        s = CurationEnvironment.Subgraph(1, 100.0, 0.0)
        π = CurationEnvironment.best_response
        nc, ns = CurationEnvironment.step(π, c, s)
        @test nc.σ < c.σ
        @test nc.xs[1] > c.xs[1]
        @test ns.v > s.v
    end
end
