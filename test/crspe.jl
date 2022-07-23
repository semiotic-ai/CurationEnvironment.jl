@testset "communitysignalauction" begin
    model = CurationEnvironment.CRSPE(CurationEnvironment.CommunitySignal())

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

    @testset "single_bidder" begin
        cs = [
            CurationEnvironment.Curator{1}(1, (110,), (0,), 100)
            CurationEnvironment.Curator{1}(2, (100,), (0,), 50)
        ]
        s = CurationEnvironment.Subgraph(1, 100, 0, 0.0)
        ps = [10, 0]

        cs, s = CurationEnvironment.single_bidder(model, ps, cs, s)
        @test ςs(cs[1], 1) ≈ 10
        @test σ(cs[1]) == 90
    end

    @testset "multiple_bidders" begin
        cs = [
            CurationEnvironment.Curator{1}(1, (110,), (0,), 100)
            CurationEnvironment.Curator{1}(2, (105,), (0,), 50)
        ]
        s = CurationEnvironment.Subgraph(1, 100, 0, 0.0)
        ps = [10, 5]

        cs, s = CurationEnvironment.multiple_bidders(model, ps, cs, s)
        @test ςs(cs[1], 1) ≈ 5
        @test σ(cs[1]) == 95

        # Test when there are two equally good bids, the winner is
        # the first one to bid.
        cs = [
            CurationEnvironment.Curator{1}(1, (110,), (0,), 100)
            CurationEnvironment.Curator{1}(2, (110,), (0,), 50)
        ]
        s = CurationEnvironment.Subgraph(1, 100, 0, 0.0)
        ps = [10, 10]

        cs, s = CurationEnvironment.multiple_bidders(model, ps, cs, s)
        @test ςs(cs[1], 1) ≈ 10
        @test σ(cs[1]) == 90
    end

    @testset "auction" begin
        # Single bid
        cs = [
            CurationEnvironment.Curator{1}(1, (110,), (0,), 100)
            CurationEnvironment.Curator{1}(2, (100,), (0,), 50)
        ]
        s = CurationEnvironment.Subgraph(1, 100, 0, 0.0)
        ps = [10, 0]

        cs, s = CurationEnvironment.auction(model, ps, cs, s)
        @test ςs(cs[1], 1) ≈ 10
        @test σ(cs[1]) == 90

        # Multiple bids
        cs = [
            CurationEnvironment.Curator{1}(1, (110,), (0,), 100)
            CurationEnvironment.Curator{1}(2, (105,), (0,), 50)
        ]
        s = CurationEnvironment.Subgraph(1, 100, 0, 0.0)
        ps = [10, 5]

        cs, s = CurationEnvironment.auction(model, ps, cs, s)
        @test ςs(cs[1], 1) ≈ 5
        @test σ(cs[1]) == 95

        # No bids
        cs = [
            CurationEnvironment.Curator{1}(1, (100,), (0,), 100)
            CurationEnvironment.Curator{1}(2, (100,), (0,), 50)
        ]
        s = CurationEnvironment.Subgraph(1, 100, 0, 0.0)
        ps = [0, 0]

        cs, s = CurationEnvironment.auction(model, ps, cs, s)
        @test ςs(cs[1], 1) ≈ 0
        @test σ(cs[1]) == 100
        @test ςs(cs[2], 1) ≈ 0
        @test σ(cs[2]) == 50
    end

    @testset "burn" begin
        cs = [
            CurationEnvironment.Curator{1}(1, (0,), (10,), 90)
            CurationEnvironment.Curator{1}(2, (110,), (0,), 50)
        ]
        s = CurationEnvironment.Subgraph(1, 110, 10, 0.0)
        ps = [-110, 0]

        cs, s = CurationEnvironment.burn(model, ps, cs, s)
        @test ςs(cs[1], 1) ≈ 0
        @test σ(cs[1]) == 200
    end

    @testset "step" begin
        πs = map(_ -> CurationEnvironment.best_response, 1:2)
        cs = [
            CurationEnvironment.Curator{1}(1, (110,), (0,), 100)
            CurationEnvironment.Curator{1}(2, (90,), (10,), 50)
        ]
        s = CurationEnvironment.Subgraph(1, 100, 10, 0.0)
        cs, s = CurationEnvironment.step(model, πs, cs, s)
        @test ςs(cs[1], 1) ≈ 1
        @test σ(cs[1]) ≈ 90
        @test ςs(cs[2], 1) ≈ 9.5
        @test σ(cs[2]) ≈ 55
    end
end
