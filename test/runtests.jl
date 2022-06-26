using CurationEnvironment
using Test

@testset "CurationEnvironment.jl" begin
    include("domainmodel.jl")
    include("policy.jl")
    include("environment.jl")
end
