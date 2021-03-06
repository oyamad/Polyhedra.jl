export convexhull, convexhull!, conichull

const HAny{N, T} = Union{HRep{N, T}, HRepElement{N, T}}
const VAny{N, T} = Union{VRep{N, T}, VRepElement{N, T}}

"""
    intersect(P1::HRep, P2::HRep)

Takes the intersection of `P1` and `P2` ``\\{\\, x : x \\in P_1, x \\in P_2 \\,\\}``.
It is very efficient between two H-representations or between two polyhedron for which the H-representation has already been computed.
However, if `P1` (resp. `P2`) is a polyhedron for which the H-representation has not been computed yet, it will trigger a representation conversion which is costly.
See the [Polyhedral Computation FAQ](http://www.cs.mcgill.ca/~fukuda/soft/polyfaq/node25.html) for a discussion on this operation.

The type of the result will be chosen closer to the type of `P1`. For instance, if `P1` is a polyhedron (resp. H-representation) and `P2` is a H-representation (resp. polyhedron), `intersect(P1, P2)` will be a polyhedron (resp. H-representation).
If `P1` and `P2` are both polyhedra (resp. H-representation), the resulting polyhedron type (resp. H-representation type) will be computed according to the type of `P1`.
The coefficient type however, will be promoted as required taking both the coefficient type of `P1` and `P2` into account.
"""
function Base.intersect(p::HRep{N}...) where N
    T = promote_coefficienttype(p)
    similar(p, hmap((i, x) -> similar_type(typeof(x), T)(x), FullDim{N}(), T, p...)...)
end
Base.intersect(p::Rep, el::HRepElement) = p ∩ intersect(el)
Base.intersect(el::HRepElement, p::Rep) = p ∩ el

Base.intersect(hps::HyperPlane...) = hrep([hps...])
Base.intersect(hss::HalfSpace...) = hrep([hss...])
Base.intersect(h1::HyperPlane{N, T}, h2::HalfSpace{N, T}) where {N, T} = hrep([h1], [h2])
Base.intersect(h1::HalfSpace{N, T}, h2::HyperPlane{N, T}) where {N, T} = h2 ∩ h1
Base.intersect(p1::HAny{N, T}, p2::HAny{N, T}, ps::HAny{N, T}...) where {N, T} = intersect(p1 ∩ p2, ps...)
function Base.intersect(p::HAny{N}...) where N
    T = promote_type(MultivariatePolynomials.coefficienttype.(p)...)
    f(p) = similar_type(typeof(p), T)(p)
    intersect(f.(p)...)
end


"""
    intersect!(p::HRep{N}, h::Union{HRepresentation{N}, HRepElement{N}})

Same as [`intersect`](@ref) except that `p` is modified to be equal to the intersection.
"""
Base.intersect!(p::HRep{N}, ::Union{HRepresentation{N}, HRepElement{N}}) where {N} = error("intersect! not implemented for $(typeof(p)). It probably does not support in-place modification, try `intersect` (without the `!`) instead.")
function Base.intersect!(p::Polyhedron{N}, h::Union{HRepresentation{N}, HRepElement{N}}) where N
    resethrep!(p, hrep(p) ∩ h)
end

"""
    convexhull(P1::VRep, P2::VRep)

Takes the convex hull of `P1` and `P2` ``\\{\\, \\lambda x + (1-\\lambda) y : x \\in P_1, y \\in P_2 \\,\\}``.
It is very efficient between two V-representations or between two polyhedron for which the V-representation has already been computed.
However, if `P1` (resp. `P2`) is a polyhedron for which the V-representation has not been computed yet, it will trigger a representation conversion which is costly.

The type of the result will be chosen closer to the type of `P1`. For instance, if `P1` is a polyhedron (resp. V-representation) and `P2` is a V-representation (resp. polyhedron), `convexhull(P1, P2)` will be a polyhedron (resp. V-representation).
If `P1` and `P2` are both polyhedra (resp. V-representation), the resulting polyhedron type (resp. V-representation type) will be computed according to the type of `P1`.
The coefficient type however, will be promoted as required taking both the coefficient type of `P1` and `P2` into account.
"""
function convexhull(p::VRep{N}...) where N
    T = promote_coefficienttype(p)
    similar(p, vmap((i, x) -> similar_type(typeof(x), T)(x), FullDim{N}(), T, p...)...)
end
convexhull(p::Rep, el::VRepElement) = convexhull(p, convexhull(el))
convexhull(el::VRepElement, p::Rep) = convexhull(p, el)

convexhull(ps::AbstractPoint...) = vrep([ps...])
convexhull(ls::Line...) = vrep([ls...])
convexhull(rs::Ray...) = vrep([rs...])
convexhull(p::AbstractPoint{N, T}, r::Union{Line{N, T}, Ray{N, T}}) where {N, T} = vrep([p], [r])
convexhull(r::Union{Line{N, T}, Ray{N, T}}, p::AbstractPoint{N, T}) where {N, T} = convexhull(p, r)
convexhull(l::Line{N, T}, r::Ray{N, T}) where {N, T} = vrep([l], [r])
convexhull(r::Ray{N, T}, l::Line{N, T}) where {N, T} = convexhull(l, r)
convexhull(p1::VAny{N, T}, p2::VAny{N, T}, ps::VAny{N, T}...) where {N, T} = convexhull(convexhull(p1, p2), ps...)
function convexhull(p::VAny{N}...) where N
    T = promote_type(MultivariatePolynomials.coefficienttype.(p)...)
    f(p) = similar_type(typeof(p), T)(p)
    convexhull(f.(p)...)
end

"""
    convexhull!(p1::VRep, p2::VRep)

Same as [`convexhull`](@ref) except that `p1` is modified to be equal to the convex hull.
"""
convexhull!(p::VRep{N}, ine::VRepresentation{N}) where {N} = error("convexhull! not implemented for $(typeof(p)). It probably does not support in-place modification, try `convexhull` (without the `!`) instead.")
function convexhull!(p::Polyhedron{N}, v::VRepresentation{N}) where N
    resetvrep!(p, convexhull(vrep(p), v))
end

# conify: same than conichull except that conify(::VRepElement) returns a VRepElement and not a V-representation
conify(v::VRep) = vrep(lines(v), [collect(rays(v)); Ray.(collect(points(v)))])
conify(v::VCone) = v
conify(p::AbstractPoint) = Ray(p)
conify(r::Union{Line, Ray}) = r

conichull(p...) = convexhull(conify.(p)...)

function sumpoints(::FullDim{N}, ::Type{T}, p1, p2) where {N, T}
    _tout(p) = similar_type(typeof(p), T)(p)
    ps = [_tout(po1 + po2) for po1 in points(p1) for po2 in points(p2)]
    tuple(ps)
end
sumpoints(::FullDim{N}, ::Type{T}, p1::Rep, p2::VCone) where {N, T} = RepIterator{N, T}.(preps(p1))
sumpoints(::FullDim{N}, ::Type{T}, p1::VCone, p2::Rep) where {N, T} = RepIterator{N, T}.(preps(p2))

function Base.:+(p1::VRep{N, T1}, p2::VRep{N, T2}) where {N, T1, T2}
    T = typeof(zero(T1) + zero(T2))
    similar((p1, p2), FullDim{N}(), T, sumpoints(FullDim{N}(), T, p1, p2)..., RepIterator{N, T}.(rreps(p1, p2))...)
end
Base.:+(p::Rep, el::Union{Line, Ray}) = p + vrep([el])
Base.:+(el::Union{Line, Ray}, p::Rep) = p + el

# p1 has priority
function usehrep(p1::Polyhedron, p2::Polyhedron)
    hrepiscomputed(p1) && (!vrepiscomputed(p1) || hrepiscomputed(p2))
end

function hcartesianproduct(p1::HRep{N1}, p2::HRep{N2}) where {N1, N2}
    d = FullDim{N1+N2}()
    T = promote_coefficienttype((p1, p2))
    f = (i, x) -> zeropad(x, i == 1 ? N2 : -N1)
    similar((p1, p2), d, T, hmap(f, d, T, p1, p2)...)
end
function vcartesianproduct(p1::VRep{N1}, p2::VRep{N2}) where {N1, N2}
    d = FullDim{N1+N2}()
    T = promote_coefficienttype((p1, p2))
    # Always type of first arg
    f1 = (i, x) -> zeropad(x, N2)
    f2 = (i, x) -> zeropad(x, -N1)
    q1 = similar(p1, d, T, vmap(f1, d, T, p1)...)
    q2 = similar(p2, d, T, vmap(f2, d, T, p2)...)
    q1 + q2
end
cartesianproduct(p1::HRep, p2::HRep) = hcartesianproduct(p1, p2)
cartesianproduct(p1::VRep, p2::VRep) = vcartesianproduct(p1, p2)

function cartesianproduct(p1::Polyhedron, p2::Polyhedron)
    if usehrep(p1, p2)
        hcartesianproduct(p1, p2)
    else
        vcartesianproduct(p1, p2)
    end
end

"""
    *(p1::Rep, p2::Rep)

Cartesian product between the polyhedra `p1` and `p2`.
"""
Base.:(*)(p1::Rep, p2::Rep) = cartesianproduct(p1, p2)

"""
    \\(P::AbstractMatrix, p::HRep)

Transform the polyhedron represented by ``p`` into ``P^{-1} p`` by transforming each halfspace ``\\langle a, x \\rangle \\le \\beta`` into ``\\langle P^\\top a, x \\rangle \\le \\beta`` and each hyperplane ``\\langle a, x \\rangle = \\beta`` into ``\\langle P^\\top a, x \\rangle = \\beta``.
"""
Base.:(\)(P::AbstractMatrix, rep::HRep) = rep / P'

"""
    /(p::HRep, P::AbstractMatrix)

Transform the polyhedron represented by ``p`` into ``P^{-T} p`` by transforming each halfspace ``\\langle a, x \\rangle \\le \\beta`` into ``\\langle P a, x \\rangle \\le \\beta`` and each hyperplane ``\\langle a, x \\rangle = \\beta`` into ``\\langle P a, x \\rangle = \\beta``.
"""
function Base.:(/)(p::HRep{Nin, Tin}, P::AbstractMatrix) where {Nin, Tin}
    if size(P, 2) != Nin
        throw(DimensionMismatch("The number of rows of P must match the dimension of the H-representation"))
    end
    f = (i, h) -> h / P
    # For a matrix P of StaticArrays, `d` should be type stable
    d = FullDim{size(P, 1)}()
    T = _promote_type(Tin, eltype(P))
    similar(p, d, T, hmap(f, d, T, p)...)
end

function Base.:(*)(rep::HRep, P::AbstractMatrix)
    warn("`*(p::HRep, P::AbstractMatrix)` is deprecated. Use `P \\ p` or `p / P'` instead.")
    P \ rep
end

"""
    *(P::AbstractMatrix, p::VRep)

Transform the polyhedron represented by ``p`` into ``P p`` by transforming each element of the V-representation (points, symmetric points, rays and lines) `x` into ``P x``.
"""
function Base.:(*)(P::AbstractMatrix, p::VRep{Nin, Tin}) where {Nin, Tin}
    if size(P, 2) != Nin
        throw(DimensionMismatch("The number of rows of P must match the dimension of the V-representation"))
    end
    f = (i, v) -> P * v
    # For a matrix P of StaticArrays, `d` should be type stable
    d = FullDim{size(P, 1)}()
    T = _promote_type(Tin, eltype(P))
    similar(p, d, T, vmap(f, d, T, p)...)
end
