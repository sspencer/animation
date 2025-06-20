package main

import (
	"math"
	"math/rand/v2"

	rl "github.com/gen2brain/raylib-go/raylib"
)

const (
	windowWidth  = 1600
	windowHeight = 1200
	border       = 0 // don't adjust near the border
	minSpeed     = 150
	minAdjTime   = 0.8
)

var (
	background = rl.NewColor(43, 60, 80, 255)
)

func main() {
	rl.SetConfigFlags(rl.FlagVsyncHint)

	rl.InitWindow(windowWidth, windowHeight, "Procedural Animation")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	// lastTime := rl.GetTime()
	snakes := []*snake{
		newSnake("orange", rl.Orange),
		newSnake("yellow", rl.Yellow),
		newSnake("purple", rl.Purple),
		newSnake("blue", rl.Blue),
		newSnake("red", rl.Red),
		newSnake("green", rl.Green),
		newSnake("pink", rl.Pink),
		newSnake("sky blue", rl.SkyBlue),
		//newSnake("maroon", rl.Maroon),
		newSnake("violet", rl.Violet),
		newSnake("magenta", rl.Magenta),
		newSnake("gold", rl.Gold),
	}

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		for _, s := range snakes {
			s.move(dt)
		}

		rl.BeginDrawing()
		rl.ClearBackground(background)
		for _, s := range snakes {
			s.draw()
		}

		rl.DrawFPS(10, 10)

		rl.EndDrawing()
	}
}

type snake struct {
	name       string
	pos        Vector
	dir        Vector
	chain      *Chain
	speed      float64
	color      rl.Color
	bodyFactor float32
	adjTime    float64
	adjPeriod  float64
}

func newSnake(name string, color rl.Color) *snake {

	pos := NewVector(rand.Float64()*windowWidth, rand.Float64()*windowHeight)
	dir := NewVector(randDir(), randDir())

	c := NewChain(pos, rand.IntN(24)+8, rand.IntN(24)+16, math.Pi/((rand.Float64()*4)+4))
	c.Resolve(pos)

	snake := &snake{
		name:       name,
		pos:        pos,
		dir:        dir,
		chain:      c,
		color:      color,
		speed:      float64(rand.IntN(minSpeed) + minSpeed),
		bodyFactor: rand.Float32()*4.0 + 2,
		adjPeriod:  rand.Float64()*minAdjTime + minAdjTime,
	}

	return snake
}

func (s *snake) collision(snakes []*snake, index int, dt float32) bool {
	radius := bodyWidth(0) / s.bodyFactor / 2

	for i, other := range snakes {
		if index == i {
			continue
		}
		otherRadius := bodyWidth(0) / other.bodyFactor / 2
		if rl.CheckCollisionCircles(vec2(s.pos), radius, vec2(other.pos), otherRadius) {
			s.dir.X = -s.dir.X * 2.0
			s.dir.Y = -s.dir.Y * 2.0
			s.pos.X += s.dir.X * s.speed * float64(dt)
			s.pos.Y += s.dir.Y * s.speed * float64(dt)

			return true
		}
	}

	return false
}

func (s *snake) move(dt float32) {
	s.pos.X += s.dir.X * s.speed * float64(dt)
	s.pos.Y += s.dir.Y * s.speed * float64(dt)

	curTime := rl.GetTime()
	if s.pos.X < 0 || s.pos.X > windowWidth {
		s.adjTime = curTime
		s.dir.X = -s.dir.X
	}
	if s.pos.Y < 0 || s.pos.Y > windowHeight {
		s.adjTime = curTime
		s.dir.Y = -s.dir.Y
	}

	if curTime-s.adjTime > s.adjPeriod {
		//old := s.dir
		changeDir := rand.Float64() < 0.3
		if s.dir.X > s.dir.Y {
			s.dir.X = adjustDir(s.dir.X, 0.1)
			if changeDir {
				s.dir.X = -s.dir.X
			}
		} else {
			s.dir.Y = adjustDir(s.dir.Y, 0.1)
			if changeDir {
				s.dir.Y = -s.dir.Y
			}
		}

		//fmt.Printf("adjusting %s after %0.2f seconds from %s to %s\n", s.name, curTime-s.adjTime, old, s.dir)
		s.adjTime = curTime

		//s.speed = float64(rl.Clamp(float32(s.speed+float64(rand.IntN(40)-20)), minSpeed, minSpeed*2))
		//}
	}

	s.chain.Resolve(s.pos)
}

func randDir() float64 {
	if rand.IntN(2) == 0 {
		return rand.Float64()*0.5 - 1 // [-1, -0.5)
	} else {
		return rand.Float64()*0.5 + 0.5 // [0.5, 1)
	}
}

func adjustDir(dir, change float64) float64 {
	s := dir + rand.Float64()*(change*2) - change
	if s > 1.0 {
		s = 1.0
	} else if s < -1.0 {
		s = -1.0
	}

	return s
}

func (s *snake) draw() {
	s.chain.Draw(s.color, s.bodyFactor)
}
