struct CommunitySignal <: CurationModel end

"""
    payment(::CommunitySignal, x::Number, v::Number, τ::Number)

The payment needed to capture `x` proportion of the equity for a subgraph
with valuation `v` and tax rate `τ`.
"""
function payment(::CommunitySignal, x::Number, v::Number, τ::Number)
    buyout_tax = τ * x * v
    equity_deposit = (x * v * (1 + τ * x)) / (1 - x)
    return buyout_tax + equity_deposit
end

"""
    payment(model::CommunitySignal, x::Number, s::Subgraph)

# Arguments
- `x::Number`: The proportion of equity that the curator wants to own.
- `s::Subgraph`: The subgraph the curator is making the payment to.
"""
function payment(model::CommunitySignal, x::Number, s::Subgraph)
    return payment(model, x, s.v, s.τ)
end

"""
    equity_proportion(::CommunitySignal, p::Number, v::Number, τ::Number)

The proportion of equity on a subgraph with signal `v`
the curator will receive by paying amount `p` with tax rate `τ`.
"""
function equity_proportion(::CommunitySignal, p::Number, v::Number, τ::Number)
    τ = p ≥ 0 ? τ : 0.0  # Don't apply tax when burning
    return p / ((1 + τ) * v + p)
end

"""
    equity_proportion(model::CommunitySignal, p::Number, s::Subgraph)

# Arguments
- `p::Number`: The payment the curator makes to get equity on the subgraph.
- `s::Subgraph`: The subgraph the curator is making the payment to.
"""
function equity_proportion(model::CommunitySignal, p::Number, s::Subgraph)
    return equity_proportion(model, p, s.v, s.τ)
end

"""
    shares(model::CommunitySignal, x::Number, s::Number, v::Number, τ::Number)

How many new shares were minted when a curator executes a new transaction for
equity proportion `x` on a subgraph with shares `s`, signal `v` and tax rate `τ`.
"""
function shares(model::CommunitySignal, x::Number, s::Number, v::Number, τ::Number)
    return (s / (1 - x) - s) + (s == 0) * payment(model, x, v, τ)
end

"""
    shares(model::CommunitySignal, x::Number, s::Subgraph)

How many new shares were minted when a curator executes a new transaction for
equity proportion `x` on a subgraph with shares `s`.
"""
function shares(model::CommunitySignal, x::Number, s::Subgraph)
    return shares(model, x, s.s, s.v, s.τ)
end

"""
    best_response(::CommunitySignal, v::Number, v̂::Number, τ::Number, x::Number)

Find the best response for a subgraph with signal `v` and tax rate `τ` given the curator
believes the true value of the subgraph to be `v̂`. The curator has the ratio `x` of the
total shares on the subgraph.
"""
function best_response(::CommunitySignal, v::Number, v̂::Number, τ::Number, x::Number)
    # mint
    popt = max(√((1 + τ)v * v̂) - (1 + τ)v, 0)
    # burn
    B = x * v  # token value of all equity
    bopt = -max(min((v - v̂) / 2, B), 0)
    return popt + bopt
end

"""
    best_response(model::CommunitySignal, c::Curator, s::Subgraph)

# Arguments
- `c::Curator`: The curator taking the action.
- `s::Subgraph`: The subgraph which the curator may curate.
"""
function best_response(model::CommunitySignal, c::Curator, s::Subgraph)
    # If s.s r= 0, x is / 0
    _s = s.s == 0 ? 1 : s.s
    return best_response(model, s.v, c.v̂s[s.id], s.τ, c.ses[s.id] / _s)
end

"""
    step(mode::CommunitySignal, π::Function, c::Curator, s::Subgraph)::Tuple{Curator, Subgraph}

Curator `c` takes decides how much to curate on subgraph `s` by running the policy `π`.
"""
function step(model::CommunitySignal, π::F, c::Curator, s::Subgraph) where {F<:Function}
    p = π(model, c, s)
    p = c.σ - p ≥ 0 ? p : c.σ  # Don't spend more than you've got
    x = equity_proportion(model, p, s)
    newshares = shares(model, x, s)
    M = length(c.ses)
    newses = ntuple(i -> i == s.id ? c.ses[i] + newshares : c.ses[i], Val(M))
    cout = Curator{M}(c.id, c.v̂s, newses, c.σ - p)
    sout = Subgraph(s.id, s.v + p, s.s + newshares, s.τ)

    return cout, sout
end
