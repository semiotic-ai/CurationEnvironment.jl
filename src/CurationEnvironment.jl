module CurationEnvironment

export Curator, Subgraph, CommunitySignal, CommunitySignalAuction, best_response, step

using Base: Base
using Accessors
using MLStyle

include("domainmodel.jl")
include("communitysignal.jl")
include("communitysignalauction.jl")

end
