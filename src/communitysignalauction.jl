"""
    best_response(::CommunitySignalAuction, v::Number, v̂::Number, τ::Number, x::Number)

Find the best response on the community signal auction model for a subgraph with signal
`v` and tax rate `τ` given the curator believes the true value of the subgraph to be
`v̂`. The curator has the ratio `x` of the total shares on the subgraph and available
stake `σ`.
"""
function best_response(
    ::CommunitySignalAuction, v::Number, v̂::Number, τ::Number, x::Number, σ::Number
)
    # mint
    popt = max(v̂ - (1 + τ * (1 - x)) * v, 0)
    # burn
    B = x * v  # token value of all equity
    bopt = -max(min((v - v̂) / 2, B), 0)
    p = popt + bopt
    p = σ - p ≥ 0 ? p : σ  # Don't spend more than you've got
    return p
end

"""
    best_response(model::<:CommunitySignalAuction, c::Curator, s::Subgraph)

Find the best response for curator `c` on subgraph `s`.
"""
function best_response(model::CommunitySignalAuction, c::Curator, s::Subgraph)
    # If s.s r= 0, x is / 0
    _s = s.s == 0 ? 1 : s.s
    return best_response(model, s.v, c.v̂s[s.id], s.τ, c.ses[s.id] / _s, c.σ)
end

"""
    single_bidder(m::CommunitySignalAuction, bids::Vector{<:Real}, cs::Vector{<:Curator}, s::Subgraph)

When there is only a single bidder, the bidder wins the auction. The curators `cs` make `bids` on the
subgraph `s`.
"""
function single_bidder(
    m::CommunitySignalAuction, bids::Vector{T}, cs::Vector{C}, s::Subgraph
) where {T<:Real,C<:Curator}
    i = argmax(bids)
    p = bids[i]
    c = cs[i]
    c, s = curate(m, p, c, s)
    cs = @set cs[i] = c
    return cs, s
end

"""
    multiple_bidders(m::CommunitySignalAuction, bids::Vector{<:Real}, cs::Vector{<:Curator}, s::Subgraph)

When there are multiple bidders, the bidder who is willing to pay the most pays the price of the
second-highest bid. The curators `cs` make `bids` on the subgraph `s`.
"""
function multiple_bidders(
    m::CommunitySignalAuction, bids::Vector{T}, cs::Vector{C}, s::Subgraph
) where {T<:Real,C<:Curator}
    i = argmax(bids)
    i2 = partialsortperm(bids, 2; rev=true)
    p = bids[i2]
    c = cs[i]
    c, s = curate(m, p, c, s)
    cs = @set cs[i] = c
    return cs, s
end

"""
    auction(m::CommunitySignalAuction, bids::Vector{<:Real}, cs::Vector{<:Curator}, s::Subgraph)

Runs a commit-reveal second-price auction to select which bid wins the right to curate on the
subgraph. The curators `cs` make `bids` on the subgraph `s`.
"""
function auction(
    m::CommunitySignalAuction, bids::Vector{T}, cs::Vector{C}, s::Subgraph
) where {T<:Real,C<:Curator}
    numbids = sum(bids .> 0)

    (ncs, ns) = @match numbids begin
        1 => single_bidder(m, bids, cs, s)
        if numbids > 1
        end => multiple_bidders(m, bids, cs, s)
        _ => (cs, s)
    end
    return ncs, ns
end

"""
    burn(m::CommunitySignalAuction, ps::Vector{<:Real}, cs::Vector{<:Curator}, s::Subgraph)

Curators `cs` who have negative payment in `ps` will burn shares on the subgraph `s`.
"""
function burn(
    m::CommunitySignalAuction, ps::Vector{T}, cs::Vector{C}, s::Subgraph
) where {T<:Real,C<:Curator}
    is = findall(ps .< 0)
    for i in is
        p = ps[i]
        c = cs[i]
        c, s = curate(m, p, c, s)
        cs = @set cs[i] = c
    end
    return cs, s
end

"""
    step(mode::CommunitySignalAuction, πs::Vector{<:Function}, cs::Vector{<:Curator}, s::Subgraph) → Tuple{Tuple{Curator}, Subgraph}

The curators `cs` bid in an auction on subgraph `s` according to policies `πs`.
"""
function step(
    model::CommunitySignalAuction, πs::Vector{F}, cs::Vector{C}, s::Subgraph
) where {F<:Function,C<:Curator}
    # Act per policy
    # NOTE: Here, since we use a step function rather than async exec, the policies are
    # executed together. This may be a bad assumption as burning can happen between
    # auctions, whereas minting can only happen at discrete intervals with auctions.
    ps = map((π, c) -> π(model, c, s), πs, cs)

    # Burn
    # NOTE: Here burning happens before minting arbitrarily.
    cs, s = burn(model, ps, cs, s)

    # Auction for minting
    cs, s = auction(model, ps, cs, s)

    return cs, s
end
