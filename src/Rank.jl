# Rank function

export Rank

"""
**``Rank`` lsc and subadditive **
    Rank(λ)
Returns the function
```math
f(x) = λ\\cdot rank(matrix(x))
```
for a nonnegative parameter `λ` and a vector `x`.
"""

mutable struct Rank{R<:Real,S<:AbstractArray,T,Tr,M<:AbstractArray{T}}
    lambda::R
    A::S
    F::PSVD{T,Tr,M}
    function Rank(
        lambda::R,
        A::S,
        F::PSVD{T,Tr,M},
    ) where {R<:Real,S<:AbstractArray,T,Tr,M<:AbstractArray{T}}
        if lambda < 0
            error("λ must be nonnegative")
        end
        new{typeof(lambda),typeof(A),T,Tr,M}(lambda, A, F)
    end
end


Rank(lambda::R, A::S, F::PSVD{T,Tr,M}) where {R,S,T,Tr,M<:AbstractArray{T}} =
    Rank{R,S,eltype(A),real(eltype(A)),M}(lambda, A, F)

function (f::Rank)(x::AbstractVector{R}) where {R<:Real}
    return f.lambda * rank(reshape_array(x, (size(f.A, 1), size(f.A, 2))))
end


fun_name(f::Rank) = "Rank"
fun_dom(f::Rank) = "AbstractArray{Real}"
fun_expr(f::Rank{T}) where {T<:Real} = "x ↦ rank(matrix(x))"
fun_params(f::Rank{T}) where {T<:Real} = "λ = $(f.lambda)"


function prox!(
    y::AbstractVector{R},
    f::Rank{R,S,T,Tr,M},
    x::AbstractVector{R},
    gamma::R,
) where {R<:Real,S<:AbstractArray,T,Tr,M<:AbstractArray{T}}
    f.A .= reshape_array(x, (size(f.A, 1), size(f.A, 2)))
    psvd_dd!(f.F, f.A, full = false)
    c = sqrt(2 * f.lambda * gamma)
    for i ∈ eachindex(f.F.S)
        if f.F.S[i] <= c
            f.F.U[:, i] .= 0
        else
            for j = 1:size(f.A, 1)
                f.F.U[j, i] = f.F.U[j, i] * f.F.S[i]
            end
        end
    end
    mul!(f.A, f.F.U, f.F.Vt)
    y .= reshape_array(f.A, (size(y, 1), 1))
    return y
end
