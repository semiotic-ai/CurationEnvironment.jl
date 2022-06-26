"""
    best_response(v::Number, v̂::Number, τ::Number)

Find the best response for a subgraph with signal `v` and tax rate `τ` given the curator
believes the true value of the subgraph to be `v̂`.
"""
function best_response(v, v̂, τ)
    return max(√((1 + τ)v * v̂) - (1 + τ)v, 0)
end

"""
    best_response(c, s)

# Arguments
- `c::Curator`: The curator taking the action.
- `s::Subgraph`: The subgraph which the curator may curate.
"""
function best_response(c::Curator, s::Subgraph)
    return best_response(s.v, c.v̂s[s.id], s.τ)
end
