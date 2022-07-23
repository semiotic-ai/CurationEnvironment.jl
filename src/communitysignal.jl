export CommunitySignal

struct CommunitySignal <: CurationModel end

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

"""
    payment(::CommunitySignal, x::Number, v::Number, τ::Number)

The payment needed to capture or burn `x` proportion of the equity for a subgraph
with valuation `v` and tax rate `τ`.
"""
function payment(::CommunitySignal, x::Number, v::Number, τ::Number)
    p = @match x begin
        if x ≥ 0
        end => (τ * x * v) + ((x * v * (1 + τ * x)) / (1 - x))
        _ => x * v
    end
    return p
end

"""
    payment(model::CommunitySignal, x::Number, s::Subgraph)

The payment needed to capture `x` proportion of the equity for a subgraph
`s`.
"""
function payment(model::CommunitySignal, x::Number, s::Subgraph)
    return payment(model, x, s.v, s.τ)
end

"""
    equity_proportion(::CommunitySignal, p::Number, v::Number, τ::Number)

The proportion of equity on a subgraph with signal `v` the curator will
receive by paying amount `p` with tax rate `τ`.
"""
function equity_proportion(::CommunitySignal, p::Number, v::Number, τ::Number)
    x = @match p begin
        if p ≥ 0
        end => p / ((1 + τ) * v + p)
        _ => p / v
    end
    return x
end

"""
    equity_proportion(model::CommunitySignal, p::Number, s::Subgraph)

The proportion of equity on a subgraph `s` the curator will receive by
paying amount `p`.
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
    # prevent divide by zero when selling all shares on subgraph
    shares = @match x begin
        if x < 0
        end => s * x
        _ => (s * x / (1 - x)) + (s == 0) * payment(model, x, v, τ)
    end
    return shares
end

"""
    shares(model::CommunitySignal, x::Number, s::Subgraph)

How many new shares were minted when a curator executes a new transaction for
equity proportion `x` on a subgraph with shares `s`.
"""
function shares(model::CommunitySignal, x::Number, s::Subgraph)
    return shares(model, x, s.s, s.v, s.τ)
end
