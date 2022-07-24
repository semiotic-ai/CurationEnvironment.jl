module CurationEnvironment

export best_response, step

using Base: Base
using Accessors
using MLStyle
using Lazy

include("domainmodel.jl")
include("communitysignal.jl")
include("crspe.jl")
include("doublecrspe.jl")

end
