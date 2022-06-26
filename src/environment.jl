"""
    step(π::Function, c::Curator, s::Subgraph)::Tuple{Curator, Subgraph}

Curator `c` takes decides how much to curate on subgraph `s` by running the policy `π`.
"""
function step(π::Function, c::Curator, s::Subgraph)#::Tuple{Curator, Subgraph}
    p = π(c, s)
    x = equity_proportion(p, s)
    M = length(c.xs)
    new_xs = ntuple(i -> i == s.id ? c.xs[i] + x : c.xs[i], Val(M))
    cout = Curator{M}(c.id, c.v̂s, new_xs, c.σ - p)
    sout = Subgraph(s.id, s.v + p, s.τ)
    return cout, sout
end
