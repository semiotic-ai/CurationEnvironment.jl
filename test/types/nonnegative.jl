@testset "nonnegative" begin
    # Test a single non-negative type
    s1 = CurationEnvironment.Shares(5)
    # Operations
    @test s1 + s1 == CurationEnvironment.Shares(10)
    @test s1 - s1 == CurationEnvironment.Shares(0)
    @test s1 * s1 == 25  # Units go away for * and /
    @test s1 / s1 == 1
    # Promotion with Float64
    @test s1 + 5.0 == 10
    # Conversion
    @test convert(CurationEnvironment.Shares, 5) == s1
end
