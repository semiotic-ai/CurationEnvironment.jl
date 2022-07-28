export CommunitySignal

struct CommunitySignal <: CurationModel end

"""
    best_response(::CommunitySignal, v::Real, v̂::Real, τ::Real, ξ::Real, σ::Real)

Find the best response on the community signal model for a subgraph with signal `v`
and tax rate `τ` given the curator believes the true value of the subgraph to be `v̂`.
The curator has the ratio `ξ` of the total shares on the subgraph and available stake
`σ`.
"""
function best_response(::CommunitySignal, v::Real, v̂::Real, τ::Real, ξ::Real, σ::Real)
    # mint
    popt = max(√((1 + τ)v * v̂) - (1 + τ)v, 0)
    # burn
    B = ξ * v  # token value of all equity
    bopt = -max(min((v - v̂) / 2, B), 0)
    p = popt + bopt
    p = σ - p ≥ 0 ? p : σ  # Don't spend more than you've got
    return p
end

"""
    best_response(m::CommunitySignal, c::Curator, s::Subgraph)

Find the best response for curator `c` on subgraph `s`.
"""
function best_response(m::CommunitySignal, c::Curator, s::Subgraph)
    _ς = ς(s) == 0 ? 1 : ς(s)
    return best_response(m, v(s), v̂s(c, id(s)), τ(s), ςs(c, id(s)) / _ς, σ(c))
end

"""
    best_response(::CommunitySignal, v::Real, v̂min::Real, v̂max::Real τ::Real, ξ::Real, σ::Real)

Find the best response on the community signal model for a subgraph with signal `v`
and tax rate `τ` given the min-max curator believes the true value of the subgraph to be in
the range `v̂min` and `v̂max`. The curator has the ratio `ξ` of the total shares on the
subgraph and available stake `σ`.
"""
function best_response(
    ::CommunitySignal, v::Real, v̂min::Real, v̂max::Real, τ::Real, ξ::Real, σ::Real
)
    # mint
    popt = max(√((1 + τ)v * (v̂max + τ * ξ * v)) - (1 + τ)v, v̂min - v, 0)
    # burn
    B = ξ * v  # token value of all equity
    bopt = -max(min((v - v̂min) / 2, B), 0)
    p = popt + bopt
    p = σ - p ≥ 0 ? p : σ  # Don't spend more than you've got
    return p
end

"""
    best_response(m::CommunitySignal, c::MinMaxCurator, s::Subgraph)

Find the best response for the min-max curator `c` on subgraph `s`.
"""
function best_response(m::CommunitySignal, c::MinMaxCurator, s::Subgraph)
    _ς = ς(s) == 0 ? 1 : ς(s)
    return best_response(
        m, v(s), v̂mins(c, id(s)), v̂maxs(c, id(s)), τ(s), ςs(c, id(s)) / _ς, σ(c)
    )
end

"""
    step(mode::CommunitySignal, π::Function, c::Curator, s::Subgraph)

Curator `c` takes decides how much to curate on subgraph `s` by running the policy `π`.
"""
function step(model::CommunitySignal, π::F, c::Curator, s::Subgraph) where {F<:Function}
    p = π(model, c, s)
    c, s = curate(model, p, c, s)
    return c, s
end

"""
    payment(::CommunitySignal, x::Real, v::Real, τ::Real)

The payment needed to capture or burn `x` proportion of the equity for a subgraph
with valuation `v` and tax rate `τ`.
"""
function payment(::CommunitySignal, x::Real, v::Real, τ::Real)
    p = @match x begin
        if x ≥ 0
        end => (τ * x * v) + ((x * v * (1 + τ * x)) / (1 - x))
        _ => x * v
    end
    return p
end

"""
    payment(model::CommunitySignal, x::Real, s::Subgraph)

The payment needed to capture `x` proportion of the equity for a subgraph
`s`.
"""
function payment(model::CommunitySignal, x::Real, s::Subgraph)
    return payment(model, x, v(s), τ(s))
end

"""
    equity_proportion(::CommunitySignal, p::Real, v::Real, τ::Real)

The proportion of equity on a subgraph with signal `v` the curator will
receive by paying amount `p` with tax rate `τ`.
"""
function equity_proportion(::CommunitySignal, p::Real, v::Real, τ::Real)
    x = @match p begin
        if p ≥ 0
        end => p / ((1 + τ) * v + p)
        _ => p / v
    end
    return x
end

"""
    equity_proportion(model::CommunitySignal, p::Real, s::Subgraph)

The proportion of equity on a subgraph `s` the curator will receive by
paying amount `p`.
"""
function equity_proportion(model::CommunitySignal, p::Real, s::Subgraph)
    return equity_proportion(model, p, v(s), τ(s))
end

"""
    shares(model::CommunitySignal, x::Real, s::Real, v::Real, τ::Real)

How many new shares were minted when a curator executes a new transaction for
equity proportion `x` on a subgraph with shares `ς`, signal `v` and tax rate `τ`.
"""
function shares(model::CommunitySignal, x::Real, ς::Real, v::Real, τ::Real)
    # prevent divide by zero when selling all shares on subgraph
    shares = @match x begin
        if x < 0
        end => ς * x
        _ => (ς * x / (1 - x)) + (ς == 0) * payment(model, x, v, τ)
    end
    return shares
end

"""
    shares(model::CommunitySignal, x::Real, s::Subgraph)

How many new shares were minted when a curator executes a new transaction for
equity proportion `x` on a subgraph `s`.
"""
function shares(model::CommunitySignal, x::Real, s::Subgraph)
    return shares(model, x, ς(s), v(s), τ(s))
end
