@testset "crspe" begin
    model = CurationEnvironment.CRSPE(CurationEnvironment.CommunitySignal())

    @testset "best_response" begin
        @testset "domain model method" begin
            # Test that we receive popt and pmax
            s = CurationEnvironment.Subgraph(1, 100.0, 0.0, 0.0)
            c = CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                1, (125.0,), (200.0,), (0.0,), 100.0
            )
            b = CurationEnvironment.best_response(model, c, s)
            @test b.low ≈ √(100 * 200) - 100
            @test b.high == 100.0
        end
    end

    @testset "winner" begin
        # Test case in which one bidder's b⁺ wins and they pay their own b⁻
        cs = [
            CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                1, (110.0,), (200.0,), (0.0,), 100.0
            )
            CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                2, (105.0,), (200.0,), (0.0,), 50.0
            )
        ]
        s = CurationEnvironment.Subgraph(1, 100.0, 1.0, 0.0)
        ps = StructArray([CRSPEBid(5, 10), CRSPEBid(2, 3)])
        t = mint
        cs, s = CurationEnvironment.winner(model, ps, cs, s, t)
        @test ςs(cs[1], 1) ≈ 0.05
        @test σ(cs[1]) == 95

        # Test that first bidder pays b⁺ of second bidder
        cs = [
            CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                1, (110.0,), (200.0,), (0.0,), 100.0
            )
            CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                2, (105.0,), (200.0,), (0.0,), 50.0
            )
        ]
        s = CurationEnvironment.Subgraph(1, 100.0, 1.0, 0.0)
        ps = StructArray([CRSPEBid(2, 10), CRSPEBid(3, 5)])
        t = mint
        cs, s = CurationEnvironment.winner(model, ps, cs, s, t)
        @test ςs(cs[1], 1) ≈ 0.05
        @test σ(cs[1]) == 95

        # Test two people bid same max
        cs = [
            CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                1, (110.0,), (200.0,), (0.0,), 100.0
            )
            CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                2, (105.0,), (200.0,), (0.0,), 50.0
            )
        ]
        s = CurationEnvironment.Subgraph(1, 100.0, 1.0, 0.0)
        ps = StructArray([CRSPEBid(3, 5), CRSPEBid(2, 5)])
        t = mint
        cs, s = CurationEnvironment.winner(model, ps, cs, s, t)
        @test ςs(cs[1], 1) ≈ 0.05
        @test σ(cs[1]) == 95
    end

    @testset "auction" begin
        # Single bid
        cs = [
            CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                1, (110.0,), (200.0,), (0.0,), 100.0
            )
            CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                2, (100.0,), (200.0,), (0.0,), 50.0
            )
        ]
        s = CurationEnvironment.Subgraph(1, 100.0, 1.0, 0.0)
        ps = StructArray([CRSPEBid(5, 10)])
        t = mint
        cs, s = CurationEnvironment.auction(model, ps, cs, s, t)
        @test ςs(cs[1], 1) ≈ 0.05
        @test σ(cs[1]) == 95

        # Multiple bids
        cs = [
            CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                1, (110.0,), (200.0,), (0.0,), 100.0
            )
            CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                2, (100.0,), (200.0,), (0.0,), 50.0
            )
        ]
        s = CurationEnvironment.Subgraph(1, 100.0, 1.0, 0.0)
        ps = StructArray([CRSPEBid(3, 10), CRSPEBid(2, 5)])
        t = mint
        cs, s = CurationEnvironment.auction(model, ps, cs, s, t)
        @test ςs(cs[1], 1) ≈ 0.05
        @test σ(cs[1]) == 95

        # No bids
        cs = [
            CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                1, (110.0,), (200.0,), (0.0,), 100.0
            )
            CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                2, (100.0,), (200.0,), (0.0,), 50.0
            )
        ]
        s = CurationEnvironment.Subgraph(1, 100.0, 0.0, 0.0)
        ps = StructArray(CRSPEBid[])
        t = mint
        cs, s = CurationEnvironment.auction(model, ps, cs, s, t)
        @test ςs(cs[1], 1) ≈ 0
        @test σ(cs[1]) == 100
        @test ςs(cs[2], 1) ≈ 0
        @test σ(cs[2]) == 50
    end

    @testset "mintshares" begin
        cs = [
            CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                1, (110.0,), (200.0,), (0.0,), 100.0
            )
            CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                2, (100.0,), (200.0,), (0.0,), 50.0
            )
        ]
        s = CurationEnvironment.Subgraph(1, 100.0, 1.0, 0.0)
        ps = StructArray([CRSPEBid(5, 10)])
        cs, s = CurationEnvironment.mintshares(model, ps, cs, s)
        @test ςs(cs[1], 1) ≈ 0.05
        @test σ(cs[1]) == 95
    end

    @testset "burnshares" begin
        cs = [
            CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                1, (0.0,), (200.0,), (10.0,), 90.0
            )
            CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                2, (110.0,), (200.0,), (0.0,), 50.0
            )
        ]
        s = CurationEnvironment.Subgraph(1, 110.0, 10.0, 0.0)
        ps = StructArray([CRSPEBid(-110, 0)])
        cs, s = CurationEnvironment.burnshares(model, ps, cs, s)
        @test ςs(cs[1], 1) ≈ 0
        @test σ(cs[1]) == 200
    end

    @testset "step" begin
        πs = map(_ -> CurationEnvironment.best_response, 1:2)
        cs = [
            CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                1, (110.0,), (200.0,), (0.0,), 100.0
            )
            CurationEnvironment.MinMaxCurator{1,Int64,Float64}(
                2, (90.0,), (200.0,), (10.0,), 100.0
            )
        ]
        s = CurationEnvironment.Subgraph(1, 100.0, 10.0, 0.0)
        cs, s = CurationEnvironment.step(model, πs, cs, s)
        cs, s = CurationEnvironment.step(model, πs, cs, s)
        @test σ(cs[1]) == 0
        @test σ(cs[2]) == 100
    end
end
