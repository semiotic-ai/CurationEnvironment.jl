@testset "proportional" begin
    # Test fails when < 0
    @test_throws InexactError CurationEnvironment.FeeRate(-1)
    @test_throws InexactError CurationEnvironment.FeeRate(2)
    # Test a single proportional type
    x = CurationEnvironment.FeeRate(0.5)
    # Operations
    @test x + x == 1
    @test x - x == 0
    @test x * x == 0.25
    @test x / x == 1
    # Promotion with Float64
    @test x + 5.0 == 5.5
    # Conversion
    @test convert(CurationEnvironment.FeeRate, 0.5) == x
end
