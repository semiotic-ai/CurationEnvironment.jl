export CRSPE, CRSPEBid

"""
    CRSPE <: Auction

A commit-reveal, second price auction has three stages:

1. Bid: Each participant privately bids (perhaps multiple times) via hash
commitment(s).
2. Reveal: Bidders (optionally) deposit tokens equal to their bid with a
hash verification.
3. Allocate: The highest bidder is reimbursed the difference between their
bid and the second highest bid and allocated shares in proportion to their
payment. All others are reimbursed for their deposits.

# Constructors

```julia
CRSPE{M<:Model}(m::M)
CRSPE(m::M)
```
"""
struct CRSPE{M<:Model} <: Auction
    m::M

    CRSPE{M}(m::M) where {M<:Model} = new(m)
    CRSPE(m::M) where {M<:Model} = CRSPE{M}(m)
end

struct CRSPEBid{T<:Real} <: Bid
    low::T
    high::T
end

Lazy.@forward CRSPE.m payment, equity_proportion, shares, popt, pmax, latefees

"""
    best_response(m::CRSPE{CommunitySignal}, c::MinMaxCurator, s::Subgraph)

Find the best response for the min-max curator `c` on subgraph `s`.
"""
function best_response(m::CRSPE{CommunitySignal}, c::MinMaxCurator, s::Subgraph)
    b⁻ = popt(m, v(s), v̂mins(c, id(s)), v̂maxs(c, id(s)), τ(s), ςs(c, id(s)) / ς(s), σ(c))
    b⁺ = pmax(m, v(s), v̂maxs(c, id(s)), τ(s), ςs(c, id(s)) / ς(s), σ(c))
    b = CRSPEBid(b⁻, b⁺)
    return b
end

"""
    winner(m::CRSPE, bids::StructArray{<:CRSPEBid}, cs::Vector{<:MinMaxCurator}, s::Subgraph, t::Transaction)

Find the winner of the auction.
The bidder who is willing to pay the most pays the price of the second-highest bid.
The bidders `cs` make transaction `t` based on `bids` on the subgraph `s`.
"""
function winner(
    m::CRSPE, bids::StructArray{B}, cs::Vector{C}, s::Subgraph, t::Transaction
) where {B<:CRSPEBid,C<:MinMaxCurator}
    # NOTE: In event of tie, tie-break first using bid.low, and then by whoever is first
    maxbid = maximum(bids.high)
    is = findall(bids.high .== maxbid)
    if length(is) > 1
        maxlows = maximum(bids.low[is])
        is = findall(bids.low .== maxlows)
    end
    i = is[1]
    p = partialsort(vcat(bids.high, bids.low), 2; rev=true) * Int(t)
    c = cs[i]
    c, s = curate(m, p, c, s)
    cs = @set cs[i] = c
    return cs, s
end

"""
    auction(m::CRSPE, bids::StructArray{<:CRSPEBid}, cs::Vector{<:MinMaxCurator}, s::Subgraph, t::Transaction)

Runs a commit-reveal second-price auction to select which bid wins the right to curate on the
subgraph. The curators `cs` make transactions `t` based on `bids` on the subgraph `s`.
"""
function auction(
    m::CRSPE, bids::StructArray{B}, cs::Vector{C}, s::Subgraph, t::Transaction
) where {B<:CRSPEBid,C<:MinMaxCurator}
    (ncs, ns) = @match bids begin
        if any(bids.high .> 0)
        end => winner(m, bids, cs, s, t)
        _ => (cs, s)
    end
    return ncs, ns
end

"""
    mintshares(m::CRSPE, ps::Vector{<:CRSPEBid}, cs::Vector{<:MinMaxCurator}, s::Subgraph)

Curators `cs` who have positive payment in `ps` will mint shares on the subgraph `s`.
"""
function mintshares(
    m::CRSPE, bids::StructArray{B}, cs::Vector{C}, s::Subgraph
) where {B<:CRSPEBid,C<:MinMaxCurator}
    cs, s = auction(m, bids, cs, s, mint)
    return cs, s
end

"""
    burnshares(m::CRSPE, ps::StructArray{<:CRSPEBid}, cs::Vector{<:MinMaxCurator}, s::Subgraph)

Curators `cs` who have negative payment in `ps` will burn shares on the subgraph `s`.
"""
function burnshares(
    m::CRSPE, bids::StructArray{B}, cs::Vector{C}, s::Subgraph
) where {B<:CRSPEBid,C<:MinMaxCurator}
    is = findall(bids.low .< 0)
    for i in is
        p = bids.low[i]
        c = cs[i]
        c, s = curate(m, p, c, s)
        cs = @set cs[i] = c
    end
    return cs, s
end

"""
    step(m::CRSPE, πs::Vector{<:Function}, cs::Vector{<:AbstractCurator}, s::Subgraph) → Tuple{Tuple{Curator}, Subgraph}

The curators `cs` bid in a CRSPE auction on subgraph `s` according to policies `πs`.

NOTE: Here, since we use a step function rather than async exec, the policies are
executed together. This may be a bad assumption as burning can happen between
auctions, whereas minting can only happen at discrete intervals with auctions.
"""
function step(
    m::CRSPE, πs::Vector{F}, cs::Vector{C}, s::Subgraph
) where {F<:Function,C<:AbstractCurator}
    ps = map((π, c) -> π(m, c, s), πs, cs)
    bids = StructArray(ps)
    cs, s = burnshares(m, bids, cs, s)
    cs, s = mintshares(m, bids, cs, s)
    return cs, s
end
