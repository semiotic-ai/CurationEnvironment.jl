using CurationEnvironment
using Test

@testset "CurationEnvironment.jl" begin
    include("domainmodel.jl")
    include("communitysignal.jl")
    include("communitysignalauction.jl")
end
