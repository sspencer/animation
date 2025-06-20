package main

import (
	"fmt"
	"math"
)

// Vector represents a 2D vector with X and Y components
type Vector struct {
	X, Y float64
}

// NewVector creates a new Vector
func NewVector(x, y float64) Vector {
	return Vector{X: x, Y: y}
}

// FromAngle creates a unit vector from the given angle in radians
func FromAngle(angle float64) Vector {
	return Vector{X: math.Cos(angle), Y: math.Sin(angle)}
}

// Add returns the sum of two vectors
func (v Vector) Add(other Vector) Vector {
	return Vector{X: v.X + other.X, Y: v.Y + other.Y}
}

// Subtract returns the difference of two vectors
func (v Vector) Subtract(other Vector) Vector {
	return Vector{X: v.X - other.X, Y: v.Y - other.Y}
}

// Multiply scales the vector by a scalar
func (v Vector) Multiply(scalar float64) Vector {
	return Vector{X: v.X * scalar, Y: v.Y * scalar}
}

// Divide scales the vector by 1/scalar
func (v Vector) Divide(scalar float64) Vector {
	if scalar == 0 {
		return v // Avoid division by zero
	}
	return Vector{X: v.X / scalar, Y: v.Y / scalar}
}

// Magnitude returns the length of the vector
func (v Vector) Magnitude() float64 {
	return math.Sqrt(v.X*v.X + v.Y*v.Y)
}

// SetMag returns a new vector with the same direction but specified magnitude
func (v Vector) SetMag(newMag float64) Vector {
	return v.Normalize().Multiply(newMag)
}

// MagnitudeSquared returns the squared length (useful for performance when comparing distances)
func (v Vector) MagnitudeSquared() float64 {
	return v.X*v.X + v.Y*v.Y
}

// Distance returns the distance between two vectors
func (v Vector) Distance(other Vector) float64 {
	return v.Subtract(other).Magnitude()
}

// DistanceSquared returns the squared distance (performance optimization)
func (v Vector) DistanceSquared(other Vector) float64 {
	return v.Subtract(other).MagnitudeSquared()
}

// Normalize returns a unit vector in the same direction
func (v Vector) Normalize() Vector {
	mag := v.Magnitude()
	if mag == 0 {
		return Vector{X: 0, Y: 0}
	}
	return v.Divide(mag)
}

// Dot returns the dot product of two vectors
func (v Vector) Dot(other Vector) float64 {
	return v.X*other.X + v.Y*other.Y
}

// Cross returns the cross product magnitude (in 2D, this is a scalar)
func (v Vector) Cross(other Vector) float64 {
	return v.X*other.Y - v.Y*other.X
}

// Angle returns the angle of the vector in radians
func (v Vector) Angle() float64 {
	return math.Atan2(v.Y, v.X)
}

// Rotate rotates the vector by the given angle in radians
func (v Vector) Rotate(angle float64) Vector {
	cos := math.Cos(angle)
	sin := math.Sin(angle)
	return Vector{
		X: v.X*cos - v.Y*sin,
		Y: v.X*sin + v.Y*cos,
	}
}

// Lerp performs linear interpolation between two vectors
func (v Vector) Lerp(other Vector, t float64) Vector {
	return Vector{
		X: v.X + t*(other.X-v.X),
		Y: v.Y + t*(other.Y-v.Y),
	}
}

// String returns a string representation of the vector
func (v Vector) String() string {
	return fmt.Sprintf("(%.2f, %.2f)", v.X, v.Y)
}

// ConstrainDistance constrains the distance between two points
// If the distance is greater than maxDist, it moves the second point closer
// If the distance is less than minDist, it moves the second point further away
// Returns the new position for the second point
func ConstrainDistance(p1, p2 Vector, minDist, maxDist float64) Vector {
	diff := p2.Subtract(p1)
	dist := diff.Magnitude()

	if dist == 0 {
		// Points are at the same location, push p2 to minDist
		return p1.Add(Vector{X: minDist, Y: 0})
	}

	if dist > maxDist {
		// Too far apart, bring p2 closer
		normalized := diff.Normalize()
		return p1.Add(normalized.Multiply(maxDist))
	} else if dist < minDist {
		// Too close, push p2 further away
		normalized := diff.Normalize()
		return p1.Add(normalized.Multiply(minDist))
	}

	// Distance is within bounds, no change needed
	return p2
}

// ConstrainDistanceSymmetric constrains distance by moving both points toward/away from their midpoint
// This keeps the center of mass constant while adjusting the distance
func ConstrainDistanceSymmetric(p1, p2 Vector, minDist, maxDist float64) (Vector, Vector) {
	center := p1.Add(p2).Divide(2)
	diff := p2.Subtract(p1)
	dist := diff.Magnitude()

	if dist == 0 {
		// Points are at the same location
		halfDist := minDist / 2
		return center.Add(Vector{X: -halfDist, Y: 0}), center.Add(Vector{X: halfDist, Y: 0})
	}

	normalized := diff.Normalize()

	if dist > maxDist {
		// Too far apart
		halfDist := maxDist / 2
		return center.Subtract(normalized.Multiply(halfDist)), center.Add(normalized.Multiply(halfDist))
	} else if dist < minDist {
		// Too close
		halfDist := minDist / 2
		return center.Subtract(normalized.Multiply(halfDist)), center.Add(normalized.Multiply(halfDist))
	}

	// Distance is within bounds
	return p1, p2
}

func vectorDemo() {
	// Example usage
	fmt.Println("Vector Animation Utilities Demo")
	fmt.Println("=================================")

	// Create vectors
	v1 := NewVector(3, 4)
	v2 := NewVector(1, 2)

	fmt.Printf("v1: %s\n", v1)
	fmt.Printf("v2: %s\n", v2)
	fmt.Printf("v1 + v2: %s\n", v1.Add(v2))
	fmt.Printf("v1 - v2: %s\n", v1.Subtract(v2))
	fmt.Printf("v1 magnitude: %.2f\n", v1.Magnitude())
	fmt.Printf("Distance between v1 and v2: %.2f\n", v1.Distance(v2))
	fmt.Printf("v1 normalized: %s\n", v1.Normalize())

	fmt.Println("\nDistance Constraint Demo:")
	fmt.Println("========================")

	p1 := NewVector(0, 0)
	p2 := NewVector(10, 0)

	fmt.Printf("Original points: p1=%s, p2=%s, distance=%.2f\n", p1, p2, p1.Distance(p2))

	// Constrain distance to be between 3 and 6 units
	constrained := ConstrainDistance(p1, p2, 3, 6)
	fmt.Printf("Constrained p2: %s, new distance=%.2f\n", constrained, p1.Distance(constrained))

	// Symmetric constraint example
	p3 := NewVector(-2, 0)
	p4 := NewVector(2, 0)
	fmt.Printf("\nSymmetric constraint: p3=%s, p4=%s, distance=%.2f\n", p3, p4, p3.Distance(p4))

	new_p3, new_p4 := ConstrainDistanceSymmetric(p3, p4, 6, 10)
	fmt.Printf("After symmetric constraint: p3=%s, p4=%s, distance=%.2f\n", new_p3, new_p4, new_p3.Distance(new_p4))
}
