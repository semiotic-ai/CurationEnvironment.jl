struct Curator{M}
    id::Integer
    v̂s::NTuple{M,Number}
    xs::NTuple{M,Number}
    σ::Number

    @doc """
        Curator{M}(id::Integer, ̂vs::NTuple{M, Number}, xs::NTuple{M, Number}, σ::Number)

    `Curator` is an entity that signals tokens on subgraph to demonstrate the value of the subgraph
    to indexers. Curators are paid via query fees when on a subgraph.
    Curator `id` estimates the subgraph valuations as `v̂s` and owns `xs`
    proportions of the minted tokens on each subgraph. The curator has `σ` stake to spend.
    """
    function Curator{M}(
        id::Integer, v̂s::NTuple{M,Number}, xs::NTuple{M,Number}, σ::Number
    ) where {M}
        if id < 1
            throw(ArgumentError("Curator id must be 1 or greater."))
        end
        if σ < 0
            throw(ArgumentError("σ must be nonnegative."))
        end
        return new{M}(id, v̂s, xs, σ)
    end

    @doc """
    Curator{M}(id, ̂v, x, σ)

# Arguments
- `id::Integer`: A unique identifier for the curator.
- `v̂::Number`: The curator's valuation for a subgraph. This will be applied for M subgraphs.
- `x:: Number`: The proportion of a curator's stake on each subgraph. This will be applied for M subgraphs.
- `σ::Number`: The stake the curator owns.
"""
    function Curator{M}(id::Integer, v̂::Number, x::Number, σ::Number) where {M}
        v̂s = ntuple(_ -> v̂, Val(M))
        xs = ntuple(_ -> x, Val(M))
        return Curator{M}(id, v̂s, xs, σ)
    end
end

"""
    Subgraph(id::Integer, v::Number, τ::Number)

`Subgraph` is an entity on which curators signal tokens. Subgraph `id` has signal `v` and tax
rate `τ`
"""
struct Subgraph
    id::Integer
    v::Number
    τ::Number

    function Subgraph(id::Integer, v::Number, τ::Number)
        if τ < 0.0 || τ > 1.0
            throw(ArgumentError("τ must be between 0.0 and 1.0."))
        end
        if v < 0
            throw(ArgumentError("v must be nonnegative."))
        end
        if id < 1
            throw(ArgumentError("Subgraph id must be 1 or greater."))
        end
        return new(id, v, τ)
    end
end

"""
    payment(x::Number, v::Number, τ::Number)

`payment` computes the payment needed to capture `x` proportion of the equity for a subgraph
with valuation `v` and tax rate `τ`.
"""
function payment(x::Number, v::Number, τ::Number)
    buyout_tax = τ * x * v
    equity_deposit = (x * v * (1 + τ * x)) / (1 - x)
    return buyout_tax + equity_deposit
end

"""
    payment(x, s)

# Arguments
- `x::Number`: The proportion of equity that the curator wants to own.
- `s::Subgraph`: The subgraph the curator is making the payment to.
"""
function payment(x::Number, s::Subgraph)
    return payment(x, s.v, s.τ)
end

"""
    equity_proportion(p::Number, v::Number, τ::Number)

`equity_proportion` computes the proportion of equity on a subgraph with signal `v`
the curator will receive by paying amount `p` with tax rate `τ`.
"""
function equity_proportion(p::Number, v::Number, τ::Number)
    return p / ((1 + τ) * v + p)
end

"""
    equity_proportion(p, s)

# Arguments
- `p::Number`: The payment the curator makes to get equity on the subgraph.
- `s::Subgraph`: The subgraph the curator is making the payment to.
"""
function equity_proportion(p::Number, s::Subgraph)
    return equity_proportion(p, s.v, s.τ)
end
