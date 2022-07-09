abstract type NonNegative <: Real end

nonnegatives = [:Shares, :GRT]

for c in nonnegatives
    @eval begin
        struct $c{T<:Real} <: NonNegative
            value::T

            function $c(value::T) where {T<:Real}
                return if value < 0
                    throw(InexactError(Symbol($c), $c, value))
                else
                    new{T}(value)
                end
            end
        end
        Base.promote_rule(::Type{$c}, ::Type{T}) where {T<:Real} = T
        Base.convert(::Type{T}, a::$c) where {T<:Real} = convert(T, a.value)
        Base.convert(::Type{$c}, a::T) where {T<:NonNegative} = $c(a.value)
        Base.convert(::Type{$c}, a::T) where {T<:Real} = $c(a)
        Base.:+(a::$c, b::$c) = $c(a.value + b.value)
        Base.:-(a::$c, b::$c) = $c(a.value - b.value)
        Base.:*(a::$c, b::$c) = a.value * b.value
        Base.:/(a::$c, b::$c) = a.value / b.value
        Base.:(<)(a::$c, b::$c) = a.value < b.value
        Base.:(>)(a::$c, b::$c) = a.value > b.value
        Base.:(≤)(a::$c, b::$c) = a.value ≤ b.value
        Base.:(≥)(a::$c, b::$c) = a.value ≥ b.value
    end
end
