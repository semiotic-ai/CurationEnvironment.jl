@testset "doublecrspe" begin
    m = DoubleCRSPE(CommunitySignal())
    @testset "burntokens" begin
        cs = [
            CurationEnvironment.Curator{1,Int64,Float64}(1, (0.0,), (10.0,), 90.0)
            CurationEnvironment.Curator{1,Int64,Float64}(2, (110.0,), (5.0,), 50.0)
        ]
        s = CurationEnvironment.Subgraph(1, 110.0, 10.0, 0.0)
        ps = [-110, -55]

        cs, s = CurationEnvironment.burntokens(m, ps, cs, s)
        @test ςs(cs[1], 1) ≈ 5
        @test σ(cs[1]) == 145
    end
end
