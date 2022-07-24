export CRSPE

"""
    CRSPE(m::Model)

A commit-reveal, second price auction has three stages:

1. Bid: Each participant privately bids (perhaps multiple times) via hash
commitment(s).
2. Reveal: Bidders (optionally) deposit tokens equal to their bid with a
hash verification.
3. Allocate: The highest bidder is reimbursed the difference between their
bid and the second highest bid and allocated shares in proportion to their
payment. All others are reimbursed for their deposits.
"""
struct CRSPE <: Auction
    m::Model
end

@forward CRSPE.m payment, equity_proportion, shares, curate

"""
    best_response(::CRSPE, v::Number, v̂::Number, τ::Number, x::Number)

Find the best response on the community signal auction model for a subgraph with signal
`v` and tax rate `τ` given the curator believes the true value of the subgraph to be
`v̂`. The curator has the ratio `x` of the total shares on the subgraph and available
stake `σ`.
"""
function best_response(::CRSPE, v::Number, v̂::Number, τ::Number, x::Number, σ::Number)
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
    best_response(m::CRSPE, c::Curator, s::Subgraph)

Find the best response for curator `c` on subgraph `s`.
"""
function best_response(m::CRSPE, c::Curator, s::Subgraph)
    _ς = ς(s) == 0 ? 1 : ς(s)
    return best_response(m, v(s), v̂s(c, id(s)), τ(s), ςs(c, id(s)) / _ς, σ(c))
end

"""
    single_bidder(m::CRSPE, bids::Vector{<:Real}, cs::Vector{<:Curator}, s::Subgraph)

When there is only a single bidder, the bidder wins the auction. The curators `cs` make
transaction `t` based on `bids` on the subgraph `s`.
"""
function single_bidder(
    m::CRSPE, bids::Vector{T}, cs::Vector{C}, s::Subgraph, t::Transaction
) where {T<:Real,C<:Curator}
    i = argmax(bids)
    p = bids[i] * Int(t)
    c = cs[i]
    c, s = curate(m, p, c, s)
    cs = @set cs[i] = c
    return cs, s
end

"""
    multiple_bidders(m::CRSPE, bids::Vector{<:Real}, cs::Vector{<:Curator}, s::Subgraph)
When there are multiple bidders, the bidder who is willing to pay the most pays the price of the
second-highest bid. The curators `cs` make transaction `t` based on `bids` on the subgraph `s`.
"""
function multiple_bidders(
    m::CRSPE, bids::Vector{T}, cs::Vector{C}, s::Subgraph, t::Transaction
) where {T<:Real,C<:Curator}
    i = argmax(bids)
    i2 = partialsortperm(bids, 2; rev=true)
    p = bids[i2] * Int(t)
    c = cs[i]
    c, s = curate(m, p, c, s)
    cs = @set cs[i] = c
    return cs, s
end

"""
    auction(m::CRSPE, bids::Vector{<:Real}, cs::Vector{<:Curator}, s::Subgraph)

Runs a commit-reveal second-price auction to select which bid wins the right to curate on the
subgraph. The curators `cs` make transactions `t` based on `bids` on the subgraph `s`.
"""
function auction(
    m::CRSPE, bids::Vector{T}, cs::Vector{C}, s::Subgraph, t::Transaction
) where {T<:Real,C<:Curator}
    numbids = sum(bids .> 0)

    (ncs, ns) = @match numbids begin
        1 => single_bidder(m, bids, cs, s, t)
        if numbids > 1
        end => multiple_bidders(m, bids, cs, s, t)
        _ => (cs, s)
    end
    return ncs, ns
end

"""
    minttokens(m::CRSPE, ps::Vector{<:Real}, cs::Vector{<:Curator}, s::Subgraph)

Curators `cs` who have positive payment in `ps` will mint tokens on the subgraph `s`.
"""
function minttokens(
    m::CRSPE, ps::Vector{T}, cs::Vector{C}, s::Subgraph
) where {T<:Real,C<:Curator}
    cs, s = auction(m, ps, cs, s, mint)
    return cs, s
end

"""
    burntokens(m::CRSPE, ps::Vector{<:Real}, cs::Vector{<:Curator}, s::Subgraph)

Curators `cs` who have negative payment in `ps` will burn tokens on the subgraph `s`.
"""
function burntokens(
    m::CRSPE, ps::Vector{T}, cs::Vector{C}, s::Subgraph
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
    step(m::CRSPE, πs::Vector{<:Function}, cs::Vector{<:Curator}, s::Subgraph) → Tuple{Tuple{Curator}, Subgraph}

The curators `cs` bid in a CRSPE auction on subgraph `s` according to policies `πs`.

NOTE: Here, since we use a step function rather than async exec, the policies are
executed together. This may be a bad assumption as burning can happen between
auctions, whereas minting can only happen at discrete intervals with auctions.
"""
function step(
    m::CRSPE, πs::Vector{F}, cs::Vector{C}, s::Subgraph
) where {F<:Function,C<:Curator}
    # Act per policy
    ps = map((π, c) -> π(m, c, s), πs, cs)

    # Burn
    cs, s = burntokens(m, ps, cs, s)

    # Auction for minting
    cs, s = auction(m, ps, cs, s, mint)

    return cs, s
end
