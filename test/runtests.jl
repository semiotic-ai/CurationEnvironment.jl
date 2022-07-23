using CurationEnvironment
using Test

@testset "CurationEnvironment.jl" begin
    include("domainmodel.jl")
    include("communitysignal.jl")
    include("crspe.jl")
end
