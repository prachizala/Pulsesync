# Haversine Geospatial Radius Protocol

## Mathematical Formulation
`a = sin²(Δφ/2) + cos(φ1) * cos(φ2) * sin²(Δλ/2)`
`c = 2 * atan2(√a, √(1−a))`
`d = R * c` (where `R = 6,371 km`)

Used for emergency dispatch perimeter calculations.
