@testset "doublecrspe" begin
    m = DoubleCRSPE(CommunitySignal())
    @testset "burntokens" begin
        cs = [
            CurationEnvironment.Curator{1}(1, (0,), (10,), 90)
            CurationEnvironment.Curator{1}(2, (110,), (5,), 50)
        ]
        s = CurationEnvironment.Subgraph(1, 110, 10, 0.0)
        ps = [-110, -55]

        cs, s = CurationEnvironment.burntokens(m, ps, cs, s)
        @test ςs(cs[1], 1) ≈ 5
        @test σ(cs[1]) == 145
    end
end
