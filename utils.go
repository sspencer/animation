package main

import "math"

//// Constrain the vector to be at a certain range of the anchor
//PVector constrainDistance(PVector pos, PVector anchor, float constraint) {
//return PVector.add(anchor, PVector.sub(pos, anchor).setMag(constraint));
//}

// Constrain the angle to be within a certain range of the anchor
func constrainAngle(angle, anchor, constraint float64) float64 {
	if math.Abs(relativeAngleDiff(angle, anchor)) <= constraint {
		return simplifyAngle(angle)
	}

	if relativeAngleDiff(angle, anchor) > constraint {
		return simplifyAngle(anchor - constraint)
	}

	return simplifyAngle(anchor + constraint)
}

// relativeAngleDiff computes how the radians needed to turn the angle to match the anchor
func relativeAngleDiff(angle, anchor float64) float64 {
	angle = simplifyAngle(angle + math.Pi - anchor)
	anchor = math.Pi

	return anchor - angle
}

// Simplify the angle to be in the range [0, 2pi)
func simplifyAngle(angle float64) float64 {
	for angle >= TwoPi {
		angle -= TwoPi
	}

	for angle < 0 {
		angle += TwoPi
	}

	return angle
}
