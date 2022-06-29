@testset "stake" begin
    @testset "Stake" begin
        # Should throw and error if Stake < 0
        @test_throws ArgumentError CurationEnvironment.Stake(-1)
    end
end
