@testset "taxrate" begin
    @testset "TaxRate" begin
        # Should throw an error if TaxRate outside acceptable range
        @test_throws ArgumentError CurationEnvironment.TaxRate(2.0)

        # Should support commmon math operations for a TaxRate
        τ = CurationEnvironment.TaxRate(0.5)
        @test τ^2 == 0.25
        @test τ * 2 == 1.0
    end
end
