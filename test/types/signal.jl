@testset "signal" begin
    @testset "Signal" begin
        # Should throw and error if Signal < 0
        @test_throws ArgumentError CurationEnvironment.Signal(-1)
    end
end
