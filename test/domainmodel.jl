@testset "domainmodel" begin
    include("curator.jl")
    include("subgraph.jl")

    @test τ(0.0) == 0.0
    @test isapprox(τ(1000000), -1.0; atol=1e-5)
end
