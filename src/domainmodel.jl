export CurationModel, Auction, Model
export Transaction, mint, burn
export Curator, Subgraph
export id, v̂s, ςs, σ, v, ς, τ

abstract type CurationModel end
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

struct Curator{M}
    id::Integer
    v̂s::NTuple{M,Real}
    ςs::NTuple{M,Real}
    σ::Real

    @doc """
    Curator{M}(id::Integer, ̂vs::NTuple{M, Real}, ςs::NTuple{M, Real}, σ::Real)

`Curator` is an entity that signals tokens on subgraph to demonstrate the value
of the subgraph to indexers. Curators are paid via query fees when on a subgraph.
Curator `id` estimates the subgraph valuations as `v̂s` and owns `ςs` shares on
each subgraph. The curator has `σ` stake to spend.
    """
    function Curator{M}(
        id::Integer, v̂s::NTuple{M,Real}, ςs::NTuple{M,Real}, σ::Real
    ) where {M}
        if id < 1
            throw(ArgumentError("Curator id must be 1 or greater."))
        end
        if σ < 0
            throw(ArgumentError("Curator stake must be 0 or greater."))
        end
        return new{M}(id, v̂s, ςs, σ)
    end

    @doc """
    Curator(id::Integer, ̂vs::NTuple{M, Real}, ςs::NTuple{M, Real}, σ::Real)

Create a `Curator` without specifying the number of subgraphs.
    """
    function Curator(id::Integer, v̂s::Tuple{Real}, ςs::Tuple{Real}, σ::Real)
        if id < 1
            throw(ArgumentError("Curator id must be 1 or greater."))
        end
        return Curator{length(ςs)}(id, v̂s, ςs, σ)
    end

    @doc """
    Curator{M}(id::Integer, ̂v::Real, ς::Real, σ::Real)

The provided values of `v̂` and `ς` are replicated `M` times.
"""
    function Curator{M}(id::Integer, v̂::Real, ς::Real, σ::Real) where {M}
        v̂s = ntuple(_ -> v̂, Val(M))
        ςs = ntuple(_ -> ς, Val(M))
        return Curator{M}(id, v̂s, ςs, σ)
    end
end

id(c::Curator) = c.id
v̂s(c::Curator) = c.v̂s
v̂s(c::Curator, i) = c.v̂s[i]
ςs(c::Curator) = c.ςs
ςs(c::Curator, i) = c.ςs[i]
σ(c::Curator) = c.σ
v̂s(c::Curator, v::Real, i) = @set c.v̂s[i] = v
ςs(c::Curator, v::Real, i) = @set c.ςs[i] = v
σ(c::Curator, v::Real) = @set c.σ = v

"""
    Subgraph(id::Integer, v::Real, ς::Real, τ::Real)

`Subgraph` is an entity on which curators signal tokens. Subgraph `id` has signal `v`, shares `ς`
and tax rate `τ`
"""
struct Subgraph
    id::Integer
    v::Real
    ς::Real
    τ::Real

    function Subgraph(id::Integer, v::Real, ς::Real, τ)
        if id < 1
            throw(ArgumentError("Subgraph id must be 1 or greater."))
        end
        return new(id, v, ς, τ)
    end
end

id(s::Subgraph) = s.id
v(s::Subgraph) = s.v
ς(s::Subgraph) = s.ς
τ(s::Subgraph) = s.τ
v(s::Subgraph, v::Real) = @set s.v = v
ς(s::Subgraph, v::Real) = @set s.ς = v
τ(s::Subgraph, v::Real) = @set s.τ = v

"""
    curate(model::CurationModel, p::Real, c::Curator, s::Subgraph)

A curator `c` curates tokens `p` on subgraph `s`.
"""
function curate(model::CurationModel, p::Real, c::Curator, s::Subgraph)
    newshares = shares(model, equity_proportion(model, p, s), s)
    M = length(ςs(c))
    c = ςs(c, ςs(c, id(s)) + newshares, id(s))
    c = σ(c, σ(c) - p)
    s = v(s, v(s) + p)
    s = ς(s, ς(s) + newshares)

    return c, s
end
