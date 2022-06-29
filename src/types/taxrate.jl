"""
    TaxRate(rate::AbstractFloat)

`TaxRate` is a type that stores the tax rate `τ`.
"""
struct TaxRate{T<:AbstractFloat} <: Real
    τ::T

    function TaxRate(τ::AbstractFloat)
        if τ < 0.0 || τ > 1.0
            throw(ArgumentError("The tax rate must be between 0.0 and 1.0."))
        end
        return new{typeof(τ)}(τ)
    end
end
Base.promote(a::TaxRate, b::Real) = promote(a.τ, b)
Base.promote(a::Real, b::TaxRate) = promote(a, b.τ)
Base.promote_rule(::Type{TaxRate{T}}, ::Type{S}) where {T<:AbstractFloat,S<:Real} = T
Base.convert(::Type{Union{}}, a::TaxRate) = a.τ
