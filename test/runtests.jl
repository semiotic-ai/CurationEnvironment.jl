using CurationEnvironment
using Test

@testset "CurationEnvironment.jl" begin
    include("types/types.jl")
    include("domainmodel.jl")
    include("communitysignal.jl")
end
