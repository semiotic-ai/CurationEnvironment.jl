abstract type Proportional <: Real end

proportions = [:FeeRate]

for c in proportions
    @eval begin
        struct $c{T<:Real} <: Proportional
            value::T

            function $c(value::T) where {T<:Real}
                return if value < 0 || value > 1
                    throw(InexactError(Symbol($c), $c, value))
                else
                    new{T}(value)
                end
            end
        end
        Base.promote_rule(::Type{$c}, ::Type{T}) where {T<:Real} = T
        Base.convert(::Type{T}, a::$c) where {T<:Real} = convert(T, a.value)
        Base.convert(::Type{$c}, a::T) where {T<:Proportional} = $c(a.value)
        Base.convert(::Type{$c}, a::T) where {T<:Real} = $c(a)
        Base.:+(a::$c, b::$c) = a.value + b.value
        Base.:-(a::$c, b::$c) = a.value - b.value
        Base.:*(a::$c, b::$c) = a.value * b.value
        Base.:/(a::$c, b::$c) = a.value / b.value
        Base.:(<)(a::$c, b::$c) = a.value < b.value
        Base.:(>)(a::$c, b::$c) = a.value > b.value
        Base.:(≤)(a::$c, b::$c) = a.value ≤ b.value
        Base.:(≥)(a::$c, b::$c) = a.value ≥ b.value
    end
end
