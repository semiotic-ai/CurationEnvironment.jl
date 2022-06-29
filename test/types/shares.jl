@testset "shares" begin
    @testset "Shares" begin
        # Should throw and error if Shares < 0
        @test_throws ArgumentError CurationEnvironment.Shares(-1)
    end
end
