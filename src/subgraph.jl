"""
    Subgraph <: GraphEntity

Blockchain data is organised into subgraphs.

`Subgraph` is an entity on which curators signal tokens. Subgraph `id` has signal `v`,
shares `ς` and late fee parameter of `τ`. `τ` is related to the late fee rate by
[`τ`](@ref).

# Constructors
```julia
Subgraph{S,T}(id::S, v::T, ς::T, τ::T) where {S<:Integer,T<:Real}
Subgraph(id::<:Integer, v::<:Real, ς::<:Real, τ::<:Real)
```

See also [`Curator`](@ref)
"""
struct Subgraph{S<:Integer,T<:Real} <: GraphEntity
    id::S
    v::T
    ς::T
    τ::T

    function Subgraph{S,T}(id::S, v::T, ς::T, τ::T) where {S<:Integer,T<:Real}
        if id < 1
            throw(ArgumentError("Subgraph id must be 1 or greater."))
        end
        return new{S,T}(id, v, ς, τ)
    end
    function Subgraph(id::S, v::T, ς::T, τ::T) where {S<:Integer,T<:Real}
        return Subgraph{S,T}(id, v, ς, τ)
    end
end

v(s::Subgraph) = s.v
ς(s::Subgraph) = s.ς == 0 ? 1 : s.ς
τ(s::Subgraph) = s.τ
v(s::Subgraph, v::Real) = @set s.v = v
ς(s::Subgraph, v::Real) = @set s.ς = v
τ(s::Subgraph, v::Real) = @set s.τ = v
