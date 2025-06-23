package main

import (
	"fmt"
	"math"
	"math/rand/v2"
	"strings"

	rl "github.com/gen2brain/raylib-go/raylib"
)

const (
	ScreenWidth  = 1600
	ScreenHeight = 1200
	MinSpeed     = 100
	MaxSpeed     = 200
	NumSnakes    = 7

	CollisionTime = 1.5
	HealthCheck   = 5.0
	Digestion     = 3.0
)

type Snake struct {
	name           string
	pos            rl.Vector2
	vel            rl.Vector2
	chain          *Chain
	color          rl.Color
	bodyFactor     float32
	radius         float32
	collisionTime  float64
	collisionColor rl.Color
	ateTime        float64
}

type Food struct {
	pos    rl.Vector2
	radius float32
}

var (
	background   = rl.NewColor(43, 60, 80, 255)
	snakes       []*Snake
	food         Food
	healthTicker float64
)

func main() {
	rl.SetConfigFlags(rl.FlagVsyncHint)

	rl.InitWindow(ScreenWidth, ScreenHeight, "Snakes")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	initSnakes()
	initFood()

	pause := false
	for !rl.WindowShouldClose() {

		if !pause {
			dt := rl.GetFrameTime()
			update(dt)
			checkPicnic()
			checkCollisions()
			t := rl.GetTime()
			if t-healthTicker > HealthCheck {
				healthTicker = t
				healthCheck()
			}
		}

		rl.BeginDrawing()
		rl.ClearBackground(background)

		drawFood()
		drawSnakes()
		status()

		rl.DrawFPS(10, 10)

		rl.EndDrawing()

		if rl.IsKeyPressed(rl.KeyR) {
			initSnakes()
			initFood()
		}

		if rl.IsKeyPressed(rl.KeyP) || rl.IsKeyPressed(rl.KeySpace) {
			pause = !pause
		}
	}
}

func status() {
	statusJoints(ScreenHeight - 55)
	statusLinkSize(ScreenHeight - 25)
}

func statusLinkSize(y int32) {
	sb := strings.Builder{}

	sb.WriteString("Factor:  ")
	for _, s := range snakes {
		sb.WriteString(fmt.Sprintf("[%s]: %3d  ", s.name, int32(s.bodyFactor*100)))
	}

	rl.DrawText(sb.String(), 10, y, 20, rl.White)
}

func statusJoints(y int32) {
	sb := strings.Builder{}

	sb.WriteString("Joints:  ")
	for _, s := range snakes {
		sb.WriteString(fmt.Sprintf("[%s]: %3d  ", s.name, len(s.chain.joints)))
	}

	rl.DrawText(sb.String(), 10, y, 20, rl.White)
}

func initFood() {
	radius := rand.Float32()*30 + 10
	var border float32 = 100.0
	pos := rl.Vector2{
		X: border + rand.Float32()*(ScreenWidth-2*border),
		Y: border + rand.Float32()*(ScreenHeight-2*border),
	}

	food.radius = radius
	food.pos = pos
}

func initSnakes() {
	snakes = make([]*Snake, NumSnakes)

	for i := 0; i < NumSnakes; i++ {
		factor := rand.Float32()*0.4 + 0.15
		radius := bodyWidth(0, factor)
		speed := MinSpeed + rand.Float64()*(MaxSpeed-MinSpeed)
		angle := rand.Float64() * math.Pi * 2

		pos := rl.Vector2{
			X: radius + (rand.Float32()*ScreenWidth - 2*radius),
			Y: radius + (rand.Float32()*ScreenHeight - 2*radius),
		}

		vel := rl.Vector2{
			X: float32(math.Cos(angle) * speed),
			Y: float32(math.Sin(angle) * speed),
		}

		v := Vector{
			X: float64(pos.X),
			Y: float64(pos.Y),
		}
		chain := NewChain(v, rand.IntN(18)+12, rand.IntN(24)+12, math.Pi/((rand.Float64()*4)+4))
		chain.Resolve(v)
		snake := Snake{
			name:       fmt.Sprintf("%d", i),
			chain:      chain,
			pos:        pos,
			vel:        vel,
			radius:     radius,
			bodyFactor: factor,
			color:      randomColor(),
		}

		snakes[i] = &snake

	}
}

func healthCheck() {
	fmt.Printf("Health check: %v, %0.1f\n", food.pos, food.radius)
	for _, s := range snakes {
		s.bodyFactor *= 0.95
	}
}

func smellsFood(s *Snake) {
	// Calculate distance between snake head and food
	pos1 := vec2(s.chain.joints[0])
	pos2 := food.pos

	// Calculate distance between centers
	dx := pos2.X - pos1.X
	dy := pos2.Y - pos1.Y
	distance := float32(math.Sqrt(float64(dx*dx) + float64(dy*dy)))

	// If snake is within 250 pixels of food, head towards it and speed up
	if distance < 500 {
		// Calculate direction to food
		dirX := dx / distance
		dirY := dy / distance

		// Increase speed by 50% when heading towards food
		speed := float32(math.Sqrt(float64(s.vel.X*s.vel.X+s.vel.Y*s.vel.Y))) * 1.5

		// Set velocity towards food with increased speed
		s.vel.X = dirX * speed
		s.vel.Y = dirY * speed
	}
}

func update(dt float32) {
	t := rl.GetTime()
	for _, s := range snakes {
		// Check if snake smells food and adjust velocity if needed
		if t-s.collisionTime > CollisionTime {
			smellsFood(s)
		}
	}

	for _, s := range snakes {
		// Check if snake has recently eaten food
		speedFactor := float32(1.0)
		if s.ateTime > 0 && t-s.ateTime < HealthCheck {
			// Reduce speed by 50% if snake has eaten food recently
			speedFactor = 0.5
		}

		// Apply speed factor to velocity
		currentVelX := s.vel.X * speedFactor
		currentVelY := s.vel.Y * speedFactor

		// Update position
		//fmt.Printf("from: %v ", s.pos)
		s.pos.X += currentVelX * dt
		s.pos.Y += currentVelY * dt
		//fmt.Printf("to: %v\n", s.pos)

		// Boundary collision detection and response
		if s.pos.X-s.radius <= 0 {
			s.pos.X = s.radius
			s.vel.X = -s.vel.X
		} else if s.pos.X+s.radius >= ScreenWidth {
			s.pos.X = ScreenWidth - s.radius
			s.vel.X = -s.vel.X
		}

		if s.pos.Y-s.radius <= 0 {
			s.pos.Y = s.radius
			s.vel.Y = -s.vel.Y
		} else if s.pos.Y+s.radius >= ScreenHeight {
			s.pos.Y = ScreenHeight - s.radius
			s.vel.Y = -s.vel.Y
		}

		s.vel.X = clamp(s.vel.X, MinSpeed, MaxSpeed)
		s.vel.Y = clamp(s.vel.Y, MinSpeed, MaxSpeed)
		s.chain.Resolve(vec(s.pos))
	}
}

func clamp(v, min, max float32) float32 {
	var f float32 = 1.0
	if v < 0 {
		v = -v
		f = -1.0
	}

	if v < min {
		return min * f
	} else if v > max {
		return max * f
	}

	return v * f
}

func checkPicnic() {
	for i := 0; i < len(snakes); i++ {
		s1 := snakes[i]
		pos1 := vec2(s1.chain.joints[0])
		pos2 := food.pos

		// Calculate distance between centers
		dx := pos2.X - pos1.X
		dy := pos2.Y - pos1.Y
		distance := float32(math.Sqrt(float64(dx*dx) + float64(dy*dy)))
		minDistance := s1.radius + food.radius
		if distance < minDistance && distance > 0 {
			s1.collisionColor = rl.Gold
			s1.collisionTime = rl.GetTime()
			s1.ateTime = rl.GetTime() // Set the time when food was eaten

			sqrt := math.Sqrt(float64(food.radius))
			f := float32(sqrt / 100.0)

			s1.bodyFactor += f

			fmt.Printf("%s ate food f=%0.2f\n", s1.name, f)
			initFood()
		}
	}
}

func checkCollisions() {
	deleteId := -1
	for i, s := range snakes {
		n := len(s.chain.joints)
		f := s.bodyFactor
		if n < 6 || n > 50 || f < 0.1 || f > 0.75 {
			fmt.Printf("Deleting %s, f=%0.2f, joints=%d\n", s.name, f, n)
			deleteId = i
		}
	}

	if deleteId >= 0 {
		snakes = append(snakes[:deleteId], snakes[deleteId+1:]...)
	}

	collisionAddColor := rl.NewColor(0, 255, 0, 153)
	collisionDeleteColor := rl.NewColor(255, 0, 0, 153)

	// Check collisions between all pairs of snakes
	for i := 0; i < len(snakes); i++ {
		for j := i + 1; j < len(snakes); j++ {
			s1 := snakes[i]
			s2 := snakes[j]

			pos1 := vec2(s1.chain.joints[0])
			pos2 := vec2(s2.chain.joints[0])

			// Calculate distance between centers
			dx := pos2.X - pos1.X
			dy := pos2.Y - pos1.Y
			distance := float32(math.Sqrt(float64(dx*dx) + float64(dy*dy)))

			// Check if collision occurred
			minDistance := s1.radius + s2.radius
			if distance < minDistance && distance > 0 {
				// Collision detected - resolve it

				t := rl.GetTime()
				if t-s1.collisionTime > CollisionTime && t-s2.collisionTime > CollisionTime {
					s1.collisionTime = t
					s2.collisionTime = t
					m1 := math.Sqrt(float64(s1.vel.X*s1.vel.X) + float64(s1.vel.Y*s1.vel.Y))
					m2 := math.Sqrt(float64(s2.vel.X*s2.vel.X) + float64(s2.vel.Y*s2.vel.Y))
					var winner, loser *Snake

					if m1 > m2 {
						winner = s1
						loser = s2
					} else {
						winner = s2
						loser = s1
					}

					// 5% exchange
					n := int(math.Round(0.05 * float64(len(winner.chain.joints))))
					if n < 1 {
						n = 1
					}
					fmt.Printf("Exchange %d joints between %s (winner) and %s\n", n, winner.name, loser.name)
					for k := 0; k < n; k++ {
						winner.chain.AddJoint()
						loser.chain.DeleteJoint()
					}

					winner.collisionColor = collisionAddColor
					loser.collisionColor = collisionDeleteColor
				}

				resolveCollisionWithMass(s1, s2, dx, dy, distance)
				s1.chain.Resolve(vec(s1.pos))
				s2.chain.Resolve(vec(s2.pos))

			}
		}
	}
}

func vec2(v Vector) rl.Vector2 {
	return rl.Vector2{X: float32(v.X), Y: float32(v.Y)}
}

func vec(v rl.Vector2) Vector {
	return Vector{X: float64(v.X), Y: float64(v.Y)}
}

func resolveCollisionWithMass(s1, s2 *Snake, dx, dy, distance float32) {
	// Normalize the collision vector
	nx := dx / distance
	ny := dy / distance

	// Calculate masses based on ball radius (assuming density is constant)
	// Mass proportional to area: mass = π * r²
	mass1 := float32(math.Pi) * s1.radius * s1.radius
	mass2 := float32(math.Pi) * s2.radius * s2.radius
	totalMass := mass1 + mass2

	// Separate the balls to prevent overlap based on mass ratio
	// Heavier balls move less during separation
	overlap := s1.radius + s2.radius - distance
	separation1 := overlap * (mass2 / totalMass)
	separation2 := overlap * (mass1 / totalMass)

	s1.pos.X -= nx * separation1
	s1.pos.X -= ny * separation1
	s2.pos.X += nx * separation2
	s2.pos.X += ny * separation2

	// Calculate relative velocity
	relVelX := s2.vel.X - s1.vel.X
	relVelY := s2.vel.Y - s1.vel.Y

	// Calculate relative velocity along collision normal
	speed := relVelX*nx + relVelY*ny

	// Do not resolve if velocities are separating
	if speed > 0 {
		return
	}

	// Calculate restitution (bounciness) - perfect elastic collision
	restitution := 1.0

	// Calculate impulse scalar using proper mass formula
	impulse := float32(1.0+restitution) * speed / (1.0/mass1 + 1.0/mass2)

	// Apply impulse to velocities (inverse mass relationship)
	impulseX := impulse * nx
	impulseY := impulse * ny

	s1.vel.X += impulseX / mass1
	s1.vel.Y += impulseY / mass1
	s2.vel.Y -= impulseX / mass2
	s2.vel.Y -= impulseY / mass2
}

func randomColor() rl.Color {
	return rl.NewColor(uint8(rand.IntN(255)), uint8(rand.IntN(255)), uint8(rand.IntN(255)), 255)
}

func drawFood() {
	rl.DrawCircle(int32(food.pos.X), int32(food.pos.Y), food.radius, rl.Gold)
}

func drawSnakes() {
	for _, s := range snakes {
		color := s.color
		bodyFactor := s.bodyFactor
		c := s.chain
		const (
			lineThickness = 6
		)

		// skin
		color.A = 102
		for i, joint := range c.joints {
			if i == 0 {
				continue
			}
			size := bodyWidth(i, bodyFactor)
			rl.DrawCircle(int32(joint.X), int32(joint.Y), size, color)
		}

		// more body
		spine := rl.NewColor(255, 255, 255, 153)
		for i, joint := range c.joints {
			size := bodyWidth(i, bodyFactor) * 1.1
			rotation := float32(c.angles[i]) * 180 / math.Pi
			rec := rl.Rectangle{
				X:      float32(joint.X),
				Y:      float32(joint.Y),
				Width:  size,
				Height: size,
			}

			origin := rl.Vector2{X: size / 2, Y: size / 2}
			rl.DrawRectanglePro(rec, origin, rotation, color)
		}

		// drawSnakes head
		joint := c.joints[0]
		b := bodyWidth(0, bodyFactor)
		color.A = 204
		rl.DrawCircle(int32(joint.X), int32(joint.Y), b, color)

		// Show visual indicator when snake is in slow state after eating food
		if s.ateTime > 0 && rl.GetTime()-s.ateTime < Digestion {
			slowColor := rl.NewColor(0, 191, 255, 153) // Deep Sky Blue with transparency
			rl.DrawCircle(int32(joint.X), int32(joint.Y), b*1.4, slowColor)
		}

		if s.collisionTime > 0 && rl.GetTime()-s.collisionTime < CollisionTime {
			rl.DrawCircle(int32(joint.X), int32(joint.Y), b*1.5, s.collisionColor)
		}

		// spinal column
		for i, joint := range c.joints {
			size := bodyWidth(i, bodyFactor) / 2.0
			rotation := float32(c.angles[i]) * 180 / math.Pi
			rec := rl.Rectangle{
				X:      float32(joint.X),
				Y:      float32(joint.Y),
				Width:  size,
				Height: size,
			}

			origin := rl.Vector2{X: size / 2, Y: size / 2}
			rl.DrawRectanglePro(rec, origin, rotation, spine)
		}

		//// skin
		//color.A = 128
		//for i, joint := range c.joints {
		//	b := bodyWidth(i, bodyFactor)
		//	rl.DrawCircle(int32(joint.X), int32(joint.Y), b, color)
		//}

		// drawSnakes spine
		for i := 0; i < len(c.joints)-1; i++ {
			startJoint := c.joints[i]
			endJoint := c.joints[i+1]

			rl.DrawLineEx(vec2(startJoint), vec2(endJoint), lineThickness, spine)
		}

		rl.DrawText(s.name, int32(joint.X), int32(joint.Y), 32, rl.Black)
	}
}

func bodyWidth(i int, bodyFactor float32) float32 {
	var size float32 = 0.0
	switch i {
	case 0:
		size = 74
	case 1:
		size = 80
	default:
		size = float32(64 - i)
	}

	return size * bodyFactor
}
