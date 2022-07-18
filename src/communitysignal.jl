"""
    best_response(::<:CommunitySignal, v::Number, v̂::Number, τ::Number, x::Number)

Find the best response on the community signal model for a subgraph with signal `v`
and tax rate `τ` given the curator believes the true value of the subgraph to be `v̂`.
The curator has the ratio `x` of the total shares on the subgraph and available stake
`σ`.
"""
function best_response(
    ::CommunitySignal, v::Number, v̂::Number, τ::Number, x::Number, σ::Number
)
    # mint
    # TODO: Should this also involve x? See communitysignalauction.best_response
    popt = max(√((1 + τ)v * v̂) - (1 + τ)v, 0)
    # burn
    B = x * v  # token value of all equity
    bopt = -max(min((v - v̂) / 2, B), 0)
    p = popt + bopt
    p = σ - p ≥ 0 ? p : σ  # Don't spend more than you've got
    return p
end

"""
    best_response(model::<:CommunitySignal, c::Curator, s::Subgraph)

Find the best response for curator `c` on subgraph `s`.
"""
function best_response(model::CommunitySignal, c::Curator, s::Subgraph)
    # If s.s r= 0, x is / 0
    _s = s.s == 0 ? 1 : s.s
    return best_response(model, s.v, c.v̂s[s.id], s.τ, c.ses[s.id] / _s, c.σ)
end

"""
    step(mode::CommunitySignal, π::Function, c::Curator, s::Subgraph)::Tuple{Curator, Subgraph}

Curator `c` takes decides how much to curate on subgraph `s` by running the policy `π`.
"""
function step(model::CommunitySignal, π::F, c::Curator, s::Subgraph) where {F<:Function}
    p = π(model, c, s)
    c, s = curate(model, p, c, s)
    return c, s
end
