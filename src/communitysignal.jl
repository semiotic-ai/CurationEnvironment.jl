export CommunitySignal, latefees, utility

"""
    CommunitySignal <: CurationModel

Reflect idea of of individuals contributing to a community asset.

Under this model, curators contribute tokens to the subgraph signal, which entitles them
to shares.
The shares entitle curators to rewards.
Shares are created (minted) whenever a curator pays into the subgraph.
Shares are destroyed (burned) whenever a curator withdraws funds from the subgraph.

Part of curation involves encouraging people to curate early, rather than to curate just
before query fees come in.
In the community signal model, we encourage early curation via a late fee, a small percentage
which decreases the effectiveness of your current payment based on the amount already on the
subgraph.
The late fee amount is distributed to all curators who had entered before you, thus rewarding
them for being early.
"""
struct CommunitySignal <: CurationModel end

"""
    popt(::CommunitySignal, v::Real, v̂min::Real, v̂max::Real, τ::Real, ξ::Real)

The optimal amount to curate under the community signal model.

The subgraph has current signal `v` and fee rate `τ`.
The curator has a min valuation `v̂min,  a max valuation `v̂max`, and stake `σ`.
The curator owns `ξ` proportion of the shares on the subgraph.

See also [`utility`](@ref), [`pmax`](@ref).
"""
function popt(
    ::CommunitySignal, v::Real, v̂min::Real, v̂max::Real, τ::Real, ξ::Real, σ::Real
)
    γ⁺ = √((1 + τ)v * ((1 - ξ)v̂max + τ * ξ * v)) - (1 + τ)v
    γ⁻ = √(v * v̂max) - v
    ρ = @match γ⁺, γ⁻ begin
        if γ⁺ > 0
        end => γ⁺
        if γ⁻ ≤ 0
        end => γ⁻
        _ => 0
    end
    return min(max(ρ, v̂min - v, -ξ * v), σ)
end

"""
    pmax(::CommunitySignal, v::Real, v̂max::Real, τ::Real, ξ::Real, σ::Real)

The maximum profitable payment.

The subgraph has signal `v` and a fee rate `τ`.
The curator has a max valuation of `v̂max`, stake `σ` and owns `ξ` proportion of shares
on the subgraph.
"""
function pmax(::CommunitySignal, v::Real, v̂max::Real, τ::Real, ξ::Real, σ::Real)
    return min(max(0, v̂max - (1 + τ * (1 - ξ)) * v), σ)
end

"""
    best_response(m::CommunitySignal, v::Real, v̂min::Real,
                  v̂max::Real τ::Real, ξ::Real, σ::Real)

Find the best response on the community signal model for a subgraph with signal `v`
and tax rate `τ` given the min-max curator believes the true value of the subgraph to be in
the range `v̂min` and `v̂max`. The curator has the ratio `ξ` of the total shares on the
subgraph and available stake `σ`.
"""
function best_response(
    m::CommunitySignal, v::Real, v̂min::Real, v̂max::Real, τ::Real, ξ::Real, σ::Real
)
    p = popt(m, v, v̂min, v̂max, τ, ξ, σ)
    return p
end

"""
    best_response(m::CommunitySignal, c::MinMaxCurator, s::Subgraph)

Find the best response for the min-max curator `c` on subgraph `s`.
"""
function best_response(m::CommunitySignal, c::MinMaxCurator, s::Subgraph)
    return best_response(
        m, v(s), v̂mins(c, id(s)), v̂maxs(c, id(s)), τ(s), ςs(c, id(s)) / ς(s), σ(c)
    )
end

"""
    utility(m::CommunitySignal, p::Real, v̂min::Real, v̂max::Real, v::Real, τ::Real, ξ::Real)

Utility on for payment `p` for the min-max curator `c` for model `m` for a subgraph with
signal `v` and tax rate `τ` given the min-max curator believes the true value of the
subgraph to be in the range `v̂min` and `v̂max`. The curator has the ratio `ξ` of the total
shares on the subgraph and available stake `σ`.
"""
function utility(
    m::CommunitySignal, p::Real, v̂min::Real, v̂max::Real, v::Real, τ::Real, ξ::Real
)
    δᵥ = v + p ≥ v̂min ? 0 : Inf
    δₓ = p ≥ -ξ * v ? 0 : Inf
    if p ≥ 0
        x = equity_proportion(m, p, v, τ)
        return x * ((1 - ξ) * v̂max + τ * ξ * v) - p - δᵥ
    else
        return ((p * v̂max) / (v + p)) - p - δᵥ - δₓ
    end
end

"""
    utility(m::CommunitySignal, p::Real, c::MinMaxCurator, s::Subgraph)

Utility on for payment `p` on subgraph `s` for the min-max curator `c` for model `m`.
"""
function utility(m::CommunitySignal, p::Real, c::MinMaxCurator, s::Subgraph)
    return utility(
        m, p, v̂mins(c, id(s)), v̂maxs(c, id(s)), v(s), τ(s), ςs(c, id(s)) / ς(s)
    )
end

latefees(::CommunitySignal, x::Real, v::Real, τ::Real) = x ≥ 0 ? x * v * τ : 0.0

"""
    latefees(m::CommunitySignal, p::Real, s::Subgraph)

The late fees a curator makes for paying `p` on subgraph `s`.
"""
function latefees(m::CommunitySignal, p::Real, s::Subgraph)
    return latefees(m, equity_proportion(m, p, v(s), τ(s)), v(s), τ(s))
end

"""
    step(m::CommunitySignal, π::Function, c::AbstractCurator, s::Subgraph)

Curator `c` decides how much to curate on subgraph `s` by running the policy `π`.
"""
function step(m::CommunitySignal, π::F, c::AbstractCurator, s::Subgraph) where {F<:Function}
    p = π(m, c, s)
    c, s = curate(m, p, c, s)
    return c, s
end

"""
    step(m::CommunitySignal, π::Function, c::Tuple{AbstractCurator}, s::Subgraph)

Curators `cs` decide how much to curate on subgraph `s` by running the policy `π`.

Note that the order in which the curators execute is randomised each time `step` is called.
"""
function step(
    m::CommunitySignal, π::F, cs::Tuple{Vararg{A}}, s::Subgraph
) where {F<:Function,A<:AbstractCurator}
    is = randperm(length(cs))  # Order of curators in each step is random
    for i in is
        c = cs[i]
        c, s = step(m, π, c, s)
        cs = @set cs[i] = c
    end
    return cs, s
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
        # TODO: Do we need this check on ς == 0?
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
