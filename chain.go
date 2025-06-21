package main

import (
	"math"
)

const (
	TwoPi = 2 * math.Pi
)

type Chain struct {
	joints          []Vector
	linkSize        int       // Space between joints
	angles          []float64 // used in non-FABRIK resolution
	angleConstraint float64   // Max angle diff between two adjacent joints, higher = loose, lower = rigid
}

func NewChain(origin Vector, jointCount int, linkSize int, angleConstraint float64) *Chain {
	c := &Chain{
		linkSize:        linkSize,
		angleConstraint: angleConstraint,
	}

	c.joints = append(c.joints, origin)
	c.angles = append(c.angles, 0)

	for i := 1; i < jointCount; i++ {
		c.joints = append(c.joints, c.joints[i-1].Add(NewVector(0, float64(linkSize))))
		c.angles = append(c.angles, 0)
	}

	return c
}

func (c *Chain) Resolve(pos Vector) {
	// Use linear interpolation to smoothly move the first joint toward the target position
	// The smoothing factor controls how quickly the joint moves toward the target (0.1 = 10% of the way each frame)
	smoothingFactor := 0.1
	c.joints[0] = c.joints[0].Lerp(pos, smoothingFactor)

	//angles.set(0, PVector.sub(pos, joints.get(0)).heading());
	c.angles[0] = pos.Subtract(c.joints[0]).Angle()

	for i := 1; i < len(c.joints); i++ {
		curAngle := c.joints[i-1].Subtract(c.joints[i]).Angle()
		c.angles[i] = constrainAngle(curAngle, c.angles[i-1], c.angleConstraint)
		c.joints[i] = c.joints[i-1].Subtract(FromAngle(c.angles[i]).SetMag(float64(c.linkSize)))
	}
}

func (c *Chain) DeleteJoint() {
	if len(c.joints) > 3 {
		c.joints = c.joints[:len(c.joints)-1]
		c.angles = c.angles[:len(c.angles)-1]
		c.Resolve(c.joints[0])
	}
}

func (c *Chain) AddJoint() {
	lastJoint := c.joints[len(c.joints)-1]
	var newJoint Vector

	if len(c.joints) == 1 {
		// If there's only one joint, add a new joint directly below it
		newJoint = lastJoint.Add(NewVector(0, float64(c.linkSize)))
	} else {
		// Calculate direction from second last to last joint
		secondLastJoint := c.joints[len(c.joints)-2]
		direction := lastJoint.Subtract(secondLastJoint).Normalize()

		// Add new joint in the same direction
		newJoint = lastJoint.Add(direction.SetMag(float64(c.linkSize)))
	}

	c.joints = append(c.joints, newJoint)

	// Add a new angle (use the same angle as the last joint)
	lastAngle := c.angles[len(c.angles)-1]
	c.angles = append(c.angles, lastAngle)

	// Resolve the chain to ensure proper positioning
	c.Resolve(c.joints[0])
}
