export Curator, Subgraph

abstract type CurationModel end
abstract type Auction end

# These functions enable broadcasting of CurationModels in functions
Base.length(::T) where {T<:CurationModel} = 1
Base.iterate(model::T) where {T<:CurationModel} = (model, nothing)
Base.iterate(model::T, state) where {T<:CurationModel} = nothing

# These functions enable broadcasting of CurationModels in functions
Base.length(::T) where {T<:Auction} = 1
Base.iterate(model::T) where {T<:Auction} = (model, nothing)
Base.iterate(model::T, state) where {T<:Auction} = nothing

struct Curator{M}
    id::Integer
    v̂s::NTuple{M,Real}
    ses::NTuple{M,Real}
    σ::Real

    @doc """
    Curator{M}(id::Integer, ̂vs::NTuple{M, Real}, ses::NTuple{M, Real}, σ::Real)

`Curator` is an entity that signals tokens on subgraph to demonstrate the value of the subgraph
to indexers. Curators are paid via query fees when on a subgraph.
Curator `id` estimates the subgraph valuations as `v̂s` and owns `ses`
minted tokens on each subgraph. The curator has `σ` stake to spend.
    """
    function Curator{M}(
        id::Integer, v̂s::NTuple{M,Real}, ses::NTuple{M,Real}, σ::Real
    ) where {M}
        if id < 1
            throw(ArgumentError("Curator id must be 1 or greater."))
        end
        if σ < 0
            throw(ArgumentError("Curator stake must be 0 or greater."))
        end
        return new{M}(id, v̂s, ses, σ)
    end

    @doc """
    Curator(id::Integer, ̂vs::NTuple{M, Real}, ses::NTuple{M, Real}, σ::Real)

Create a `Curator` without specifying the number of subgraphs.
    """
    function Curator(id::Integer, v̂s::Tuple{Real}, ses::Tuple{Real}, σ::Real)
        if id < 1
            throw(ArgumentError("Curator id must be 1 or greater."))
        end
        return Curator{length(ses)}(id, v̂s, ses, σ)
    end

    @doc """
    Curator{M}(id, ̂v, s, σ)

# Arguments
- `id::Integer`: A unique identifier for the curator.
- `v̂::Real`: The curator's valuation for a subgraph. This will be applied for M subgraphs.
- `s:: Real`: The number of minted tokens that the curator owns. This will be applied for M subgraphs.
- `σ::Real`: The stake the curator owns.
"""
    function Curator{M}(id::Integer, v̂::Real, s::Real, σ::Real) where {M}
        v̂s = ntuple(_ -> v̂, Val(M))
        ses = ntuple(_ -> s, Val(M))
        return Curator{M}(id, v̂s, ses, σ)
    end
end

"""
    Subgraph(id::Integer, v::Real, s::Real, τ::Real)

`Subgraph` is an entity on which curators signal tokens. Subgraph `id` has signal `v`, shares `s`
and tax rate `τ`
"""
struct Subgraph
    id::Integer
    v::Real
    s::Real
    τ::Real

    function Subgraph(id::Integer, v::Real, s::Real, τ)
        if id < 1
            throw(ArgumentError("Subgraph id must be 1 or greater."))
        end
        return new(id, v, s, τ)
    end
end

"""
    curate(model::CurationModel, p::Real, c::Curator, s::Subgraph)

A curator `c` curates tokens `p` on subgraph `s`.
"""
function curate(model::CurationModel, p::Real, c::Curator, s::Subgraph)
    newshares = shares(model, equity_proportion(model, p, s), s)
    M = length(c.ses)
    c = @set c.ses[s.id] += newshares
    c = @set c.σ = c.σ - p
    s = @set s.v = s.v + p
    s = @set s.s = s.s + newshares

    return c, s
end
