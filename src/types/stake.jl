"""
    Stake(value::<:Real)

`Stake` is a type that stores the stake of an entity as `value`.
"""
struct Stake{T<:Real} <: NonNegativeReal
    value::T

    function Stake(value::T) where {T<:Real}
        if value < 0
            throw(ArgumentError("Number of type Stake must be nonnegative."))
        end
        return new{typeof(value)}(value)
    end
end
