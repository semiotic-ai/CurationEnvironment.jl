module CurationEnvironment

export Curator, Subgraph, CommunitySignal, best_response, step

using Base: Base
using ReinforcementLearning

include("domainmodel.jl")
include("communitysignal.jl")

end
