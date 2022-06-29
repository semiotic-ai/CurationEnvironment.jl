abstract type NonNegativeReal <: Real end
value(a::T) where {T<:NonNegativeReal} = a.value
Base.promote(a::T, b::Real) where {T<:NonNegativeReal} = promote(value(a), b)
Base.promote(a::Real, b::T) where {T<:NonNegativeReal} = promote(a, value(b))
function Base.promote(a::T, b::S) where {T<:NonNegativeReal,S<:NonNegativeReal}
    return promote(value(a), value(b))
end
Base.promote_rule(::Type{T}, ::Type{S}) where {T<:NonNegativeReal,S<:Real} = S
Base.promote_rule(::Type{T}, ::Type{S}) where {T<:Real,S<:NonNegativeReal} = S
Base.promote_rule(::Type{T}, ::Type{S}) where {T<:NonNegativeReal,S<:NonNegativeReal} = Real
Base.convert(::Type{Union{}}, a::T) where {T<:NonNegativeReal} = value(a)
Base.:+(a::T, b::S) where {T<:NonNegativeReal,S<:NonNegativeReal} = value(a) + value(b)
Base.:-(a::T, b::S) where {T<:NonNegativeReal,S<:NonNegativeReal} = value(a) - value(b)
Base.:*(a::T, b::S) where {T<:NonNegativeReal,S<:NonNegativeReal} = value(a) * value(b)
Base.:/(a::T, b::S) where {T<:NonNegativeReal,S<:NonNegativeReal} = value(a) / value(b)
Base.:^(a::T, b::S) where {T<:NonNegativeReal,S<:NonNegativeReal} = value(a)^value(b)
Base.:(==)(a::T, b::S) where {T<:NonNegativeReal,S<:NonNegativeReal} = value(a) == value(b)
Base.:(<)(a::T, b::S) where {T<:NonNegativeReal,S<:NonNegativeReal} = value(a) < value(b)
Base.:(>)(a::T, b::S) where {T<:NonNegativeReal,S<:NonNegativeReal} = value(a) > value(b)
Base.:(<=)(a::T, b::S) where {T<:NonNegativeReal,S<:NonNegativeReal} = value(a) <= value(b)
Base.:(>=)(a::T, b::S) where {T<:NonNegativeReal,S<:NonNegativeReal} = value(a) >= value(b)
Base.isinf(a::T) where {T<:NonNegativeReal} = isinf(value(a))
Base.isfinite(a::T) where {T<:NonNegativeReal} = isfinite(value(a))
isnonnegative(a::T) where {T<:NonNegativeReal} = true
isnonnegative(a::Number) = false
Base.eps(a::T) where {T<:NonNegativeReal} = eps(value(a))
