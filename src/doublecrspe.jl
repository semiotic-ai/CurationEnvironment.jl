export DoubleCRSPE

"""
    DoubleCRSPE(m::CRSPE)

The difference between `DoubleCRSPE` and [`CRSPE`](@ref) is that in `DoubleCRSPE`,
we burn tokens as per a CRSPE auction as well.

This can be constructed by bypassing `CRSPE` and directly specifying the
[`CurationModel`](@ref). `DoubleCRSPE(CommunitySignal())`.
"""
struct DoubleCRSPE <: Auction
    m::CRSPE

    DoubleCRSPE(m::CurationModel) = new(CRSPE(m))
end

@forward DoubleCRSPE.m payment, equity_proportion, shares
@forward DoubleCRSPE.m best_response, single_bidder, multiple_bidders, auction, minttokens

"""
    burntokens(m::DoubleCRSPE, ps::Vector{<:Real}, cs::Vector{<:Curator}, s::Subgraph)

Curators `cs` who have negative payment in `ps` will burn tokens on the subgraph `s`.
In a DoubleCRSPE auction, they will burn tokens in a CRSPE auction.
"""
function burntokens(
    m::DoubleCRSPE, ps::Vector{T}, cs::Vector{C}, s::Subgraph
) where {T<:Real,C<:Curator}
    cs, s = auction(m, -ps, cs, s, burn)
    return cs, s
end

"""
    step(m::DoubleCRSPE, πs::Vector{<:Function}, cs::Vector{<:Curator}, s::Subgraph) → Tuple{Tuple{Curator}, Subgraph}

The curators `cs` bid in a Double CRSPE auction on subgraph `s` according to policies `πs`.

NOTE: Here, since we use a step function rather than async exec, the policies are
executed together. This may be a bad assumption as burning can happen between
auctions, whereas minting can only happen at discrete intervals with auctions.
"""
function step(
    m::DoubleCRSPE, πs::Vector{F}, cs::Vector{C}, s::Subgraph
) where {F<:Function,C<:Curator}
    # Act per policy
    ps = map((π, c) -> π(m, c, s), πs, cs)

    # Burn
    cs, s = burntokens(m, ps, cs, s)

    # Auction for minting
    cs, s = auction(m, ps, cs, s, mint)

    return cs, s
end

# TODO: Plot utility over time
