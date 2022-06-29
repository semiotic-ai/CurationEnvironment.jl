"""
    Signal(value::<:Real)

`Signal` is a type that stores the signal on a subgraph as `value`.
"""
struct Signal{T<:Real} <: NonNegativeReal
    value::T

    function Signal(value::T) where {T<:Real}
        if value < 0
            throw(ArgumentError("Number of type Signal must be nonnegative."))
        end
        return new{typeof(value)}(value)
    end
end
