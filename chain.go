package main

import (
	"math"

	rl "github.com/gen2brain/raylib-go/raylib"
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
		//joints.add(PVector.add(joints.get(i - 1), new PVector(0, this.linkSize)));
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
		//	float curAngle = PVector.sub(joints.get(i - 1), joints.get(i)).heading();
		curAngle := c.joints[i-1].Subtract(c.joints[i]).Angle()
		//	angles.set(i, constrainAngle(curAngle, angles.get(i - 1), angleConstraint));
		c.angles[i] = constrainAngle(curAngle, c.angles[i-1], c.angleConstraint)
		//	joints.set(i, PVector.sub(joints.get(i - 1), PVector.fromAngle(angles.get(i)).setMag(linkSize)));
		c.joints[i] = c.joints[i-1].Subtract(FromAngle(c.angles[i]).SetMag(float64(c.linkSize)))
	}
}

func (c *Chain) Draw(color rl.Color, bodyFactor float32) {
	const (
		//innerRadius   = 16
		//outerRadius   = 24
		lineThickness = 6
	)
	for i := 0; i < len(c.joints)-1; i++ {
		startJoint := c.joints[i]
		endJoint := c.joints[i+1]

		rl.DrawLineEx(vec2(startJoint), vec2(endJoint), lineThickness, color)
	}

	color.A = 128
	for i, joint := range c.joints {
		b := bodyWidth(i) / bodyFactor
		//rl.DrawRing(vec2(joint), b-10, b, 0, 360, 72, color)
		rl.DrawCircle(int32(joint.X), int32(joint.Y), b, color)
	}

	joint := c.joints[0]
	b := bodyWidth(0) / bodyFactor
	color.A = 255
	rl.DrawCircle(int32(joint.X), int32(joint.Y), b, color)

}

func bodyWidth(i int) float32 {
	switch i {
	case 0:
		return 74
	case 1:
		return 80
	default:
		return float32(64 - i)
	}
}

func vec2(v Vector) rl.Vector2 {
	return rl.Vector2{X: float32(v.X), Y: float32(v.Y)}
}

func vec(p rl.Vector2) Vector {
	return Vector{X: float64(p.X), Y: float64(p.Y)}
}
