@testset "policy" begin
    @testset "best_response" begin
        @testset "direct method" begin
            # If v̂ = v, don't curate the subgraph
            v = 100
            v̂ = 100
            τ = 0.0
            popt = CurationEnvironment.best_response(v, v̂, τ)
            @test popt == 0.0

            # The greater v̂ is than v, curate more
            v = 100
            v̂s = [100, 150, 200]
            τ = 0.01
            popts = CurationEnvironment.best_response.(v, v̂s, τ)
            @test issorted(popts)

            # The greater τ is, the less I will curate for the same v and v̂
            v = 100
            v̂ = 200
            τs = [0.0, 0.01, 0.1, 0.5]
            popts = CurationEnvironment.best_response.(v, v̂, τs)
            @test issorted(popts; rev=true)
        end

        @testset "domain model method" begin
            s = CurationEnvironment.Subgraph(1, 100, 0.0)
            c = CurationEnvironment.Curator{1}(1, (100,), (0,), 100)
            popt = CurationEnvironment.best_response(c, s)
            @test popt == 0.0
        end
    end
end
