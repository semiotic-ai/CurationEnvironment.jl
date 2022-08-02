export Curator, MinMaxCurator
export v̂s, ςs, σ, v̂mins, v̂maxs

"""
`AbstractCurator` is the abstract type for all curators.

All properties of an `AbstractCurator` will have an associated getter and setter.
For example, the [`Curator`](@ref) concretion has methods: `id`, `v̂s`, `ςs`, and `σ`.
If you pass in only the `AbstractCurator`, or for some fields, the `AbstractCurator`
and an index `i`, then the method serves as a getter.
If you pass in a value `v` in addition to the parameters of the getters, the method
serves as a setter.

See also [`Curator`](@ref)
"""
abstract type AbstractCurator <: GraphEntity end

"""
    Curator{M,S,T} <: AbstractCurator

Signal tokens on a [`Subgraph`](@ref) as per a private valuation.

`Curator` is an entity that signals tokens on a [`Subgraph`](@ref) to demonstrate the value
of the subgraph to indexers. Curators are paid via query fees when on a subgraph.
Curator `id` estimates the subgraph valuations as `v̂s` and owns `ςs` shares on
each subgraph. The curator has `σ` stake to spend.

# Constructors
```julia
Curator{M,S,T}(
    id::<:Integer,
    vs::NTuple{M,T},
    ςs::NTuple{M,T},
    σ::T
) where {S<:Integer, T<:Real}

Curator{M}(id::<:Integer, ̂vs::NTuple{M,<:Real}, ςs::NTuple{M,<:Real}, σ::<:Real)
Curator(id::<:Integer, ̂vs::NTuple{M,<:Real}, ςs::NTuple{M,<:Real}, σ::<:Real)
Curator{M}(id::<:Integer, ̂v::<:Real, ς::<:Real, σ::<:Real)
```
"""
struct Curator{M,S<:Integer,T<:Real} <: AbstractCurator
    id::S
    v̂s::NTuple{M,T}
    ςs::NTuple{M,T}
    σ::T

    function Curator{M,S,T}(
        id::S, v̂s::NTuple{M,T}, ςs::NTuple{M,T}, σ::T
    ) where {M,S<:Integer,T<:Real}
        if id < 1
            throw(ArgumentError("Curator id must be 1 or greater."))
        end
        if σ < 0
            throw(ArgumentError("Curator stake must be 0 or greater."))
        end
        return new{M,S,T}(id, v̂s, ςs, σ)
    end

    function Curator{M}(
        id::S, v̂s::NTuple{M,T}, ςs::NTuple{M,T}, σ::T
    ) where {M,S<:Integer,T<:Real}
        return Curator{M,S,T}(id, v̂s, ςs, σ)
    end

    function Curator(id::S, v̂s::Tuple{T}, ςs::Tuple{T}, σ::T) where {S<:Integer,T<:Real}
        return Curator{length(ςs),S,T}(id, v̂s, ςs, σ)
    end

    function Curator{M}(id::S, v̂::T, ς::T, σ::T) where {M,S<:Integer,T<:Real}
        v̂s = ntuple(_ -> v̂, Val(M))
        ςs = ntuple(_ -> ς, Val(M))
        return Curator{M,S,T}(id, v̂s, ςs, σ)
    end
end

v̂s(c::Curator) = c.v̂s
v̂s(c::Curator, i) = c.v̂s[i]
ςs(c::Curator) = c.ςs
ςs(c::Curator, i) = c.ςs[i]
σ(c::Curator) = c.σ
function v̂s(c::Curator, i, v::Real)
    x = v̂s(c)
    x = @set x[i] = v
    return c = @set c.v̂s = x
end
function ςs(c::Curator, i, v::Real)
    x = ςs(c)
    x = @set x[i] = v
    return c = @set c.ςs = x
end
σ(c::Curator, v::Real) = @set c.σ = v

"""
    MinMaxCurator{M,S,T} <: AbstractCurator

A curator that has both a min and max valuation.

`MinMaxCurator` is a [`Curator`](@ref) that has both a minimum valuation for each subgraph
`v̂mins` and a maximum valuation per subgraph `v̂maxs`. Intuitively, `v̂min` for a subgraph is
the minimum amount of signal you would want to see on a subgraph. `v̂max` is your true
valuation of the subgraph. The other parameters are as given by [`Curator`](@ref).

# Constructors

```julia
MinMaxCurator(
    id::<:Integer,
    v̂mins::NTuple{M,<:Real},
    v̂maxs::NTuple{M,<:Real},
    ςs::NTuple{M,<:Real},
    σ::<:Real
) where {M}

MinMaxCurator{M,S,T}(
    id::S,
    v̂mins::NTuple{M,T},
    v̂maxs::NTuple{M,T},
    ςs::NTuple{M,T},
    σ::T
) where {M,S<:Integer,T<:Real}
```
"""
struct MinMaxCurator{M,S<:Integer,T<:Real} <: AbstractCurator
    c::Curator{M,S,T}
    v̂mins::NTuple{M,T}

    function MinMaxCurator{M,S,T}(
        id::Integer, v̂mins::NTuple{M,T}, v̂maxs::NTuple{M,T}, ςs::NTuple{M,T}, σ::T
    ) where {M,S<:Integer,T<:Real}
        return new{M,S,T}(Curator{M}(id, v̂maxs, ςs, σ), v̂mins)
    end
    function MinMaxCurator(
        c::Curator{M,S,T}, v̂mins::NTuple{M,T}
    ) where {M,S<:Integer,T<:Real}
        return new{M,S,T}(c, v̂mins)
    end
end

Lazy.@forward MinMaxCurator.c id, v̂s, ςs, σ

v̂mins(c::MinMaxCurator) = c.v̂mins
v̂mins(c::MinMaxCurator, i) = c.v̂mins[i]
function v̂mins(c::MinMaxCurator, i, v::Real)
    x = v̂mins(c)
    x = @set x[i] = v
    return c = @set c.v̂mins = x
end
v̂maxs(c::MinMaxCurator) = v̂s(c)
v̂maxs(c::MinMaxCurator, i) = v̂s(c, i)
v̂maxs(c::MinMaxCurator, i, v::Real) = v̂s(c, i, v)
function v̂s(c::MinMaxCurator, i, v::Real)
    x = v̂s(c.c, i, v)
    return @set c.c = x
end
function ςs(c::MinMaxCurator, i, v::Real)
    x = ςs(c.c, i, v)
    return c = @set c.c = x
end
σ(c::MinMaxCurator, v::Real) = @set c.c = σ(c.c, v)
