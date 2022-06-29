abstract type CurationModel end
# These functions enable dot application of CurationModels in functions
Base.length(::T) where {T<:CurationModel} = 1
Base.iterate(model::T) where {T<:CurationModel} = (model, nothing)
Base.iterate(model::T, state) where {T<:CurationModel} = nothing

struct Curator{M}
    id::Integer
    v̂s::NTuple{M,Number}
    ses::NTuple{M,Number}
    σ::Number

    @doc """
        Curator{M}(id::Integer, ̂vs::NTuple{M, Number}, ses::NTuple{M, Number}, σ::Number)

    `Curator` is an entity that signals tokens on subgraph to demonstrate the value of the subgraph
    to indexers. Curators are paid via query fees when on a subgraph.
    Curator `id` estimates the subgraph valuations as `v̂s` and owns `ses`
    minted tokens on each subgraph. The curator has `σ` stake to spend.
    """
    function Curator{M}(
        id::Integer, v̂s::NTuple{M,Number}, ses::NTuple{M,Number}, σ::Number
    ) where {M}
        if id < 1
            throw(ArgumentError("Curator id must be 1 or greater."))
        end
        if σ < 0
            throw(ArgumentError("σ must be nonnegative."))
        end
        return new{M}(id, v̂s, ses, σ)
    end

    @doc """
    Curator{M}(id, ̂v, s, σ)

# Arguments
- `id::Integer`: A unique identifier for the curator.
- `v̂::Number`: The curator's valuation for a subgraph. This will be applied for M subgraphs.
- `s:: Number`: The number of minted tokens that the curator owns. This will be applied for M subgraphs.
- `σ::Number`: The stake the curator owns.
"""
    function Curator{M}(id::Integer, v̂::Number, s::Number, σ::Number) where {M}
        v̂s = ntuple(_ -> v̂, Val(M))
        ses = ntuple(_ -> s, Val(M))
        return Curator{M}(id, v̂s, ses, σ)
    end
end

"""
    Subgraph(id::Integer, v::Number, s::Number, τ::Number)

`Subgraph` is an entity on which curators signal tokens. Subgraph `id` has signal `v`, shares `s`
and tax rate `τ`
"""
struct Subgraph
    id::Integer
    v::Number
    s::Number
    τ::TaxRate

    function Subgraph(id::Integer, v::Number, s::Number, τ::Number)
        if v < 0
            throw(ArgumentError("v must be nonnegative."))
        end
        if s < 0
            throw(ArgumentError("s must be nonnegative."))
        end
        if id < 1
            throw(ArgumentError("Subgraph id must be 1 or greater."))
        end
        return new(id, v, s, τ)
    end
end
