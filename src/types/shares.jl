"""
    Shares(value::<:Real)

`Shares` is a type that stores the number of shares as `value`.
"""
struct Shares{T<:Real} <: NonNegativeReal
    value::T

    function Shares(value::T) where {T<:Real}
        if value < 0
            throw(ArgumentError("Number of type Shares must be nonnegative."))
        end
        return new{typeof(value)}(value)
    end
end
