@testset "nonnegative" begin
    # Test fails when < 0
    @test_throws InexactError CurationEnvironment.Shares(-1)
    # Test a single non-negative type
    x = CurationEnvironment.Shares(5)
    # Operations
    @test x + x == CurationEnvironment.Shares(10)
    @test x - x == CurationEnvironment.Shares(0)
    @test x * x == 25  # Units go away for * and /
    @test x / x == 1
    # Promotion with Float64
    @test x + 5.0 == 10
    # Conversion
    @test convert(CurationEnvironment.Shares, 5) == x
end
