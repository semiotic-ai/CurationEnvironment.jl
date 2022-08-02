using CurationEnvironment
using StructArrays
using Test

@testset "CurationEnvironment.jl" begin
    include("domainmodel.jl")
    include("communitysignal.jl")
    include("crspe.jl")
    # include("doublecrspe.jl")
end
