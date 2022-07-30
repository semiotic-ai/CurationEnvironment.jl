export CurationModel, Auction, Model
export Transaction, mint, burn
export GraphEntity, Subgraph, Curator
export id, τ, v, ς

"Dynamics governing the interaction between a [`Subgraph`](@ref) and a [`Curator`](@ref)."
abstract type CurationModel end

"Wrap a [`CurationModel`](@ref) in an auction."
abstract type Auction end

const Model = Union{CurationModel,Auction}

@enum Transaction begin
    mint = 1
    burn = -1
end

# These functions enable broadcasting of CurationModels in functions
Base.length(::T) where {T<:CurationModel} = 1
Base.iterate(model::T) where {T<:CurationModel} = (model, nothing)
Base.iterate(model::T, state) where {T<:CurationModel} = nothing

# These functions enable broadcasting of CurationModels in functions
Base.length(::T) where {T<:Auction} = 1
Base.iterate(model::T) where {T<:Auction} = (model, nothing)
Base.iterate(model::T, state) where {T<:Auction} = nothing

"A type of entity that interacts with The Graph protocol."
abstract type GraphEntity end

"The `id` of the [`GraphEntity`](@ref)."
id(g::GraphEntity) = g.id

include("curator.jl")
include("subgraph.jl")

"Compute the fee parameter from the fee rate."
τ(f::Real) = f / (1 - f)

"""
    curate(m::CurationModel, p::Real, c::Curator, s::Subgraph)

A curator `c` curates tokens `p` on subgraph `s` as per model `m`.

See also [`Subgraph`](@ref), [`Curator`](@ref), [`CurationModel`](@ref)
"""
function curate(m::CurationModel, p::Real, c::AbstractCurator, s::Subgraph)
    newshares = shares(m, equity_proportion(m, p, s), s)
    M = length(ςs(c))
    c = ςs(c, ςs(c, id(s)) + newshares, id(s))
    c = σ(c, σ(c) - p)
    s = v(s, v(s) + p)
    s = ς(s, ς(s) + newshares)

    return c, s
end
