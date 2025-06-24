package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

BACKGROUND :: rl.Color{43, 60, 80, 255}
SNAKE_COUNT :: 8
// MIN_RADIUS :: 10
MAX_RADIUS :: 65
MIN_LINK_LENGTH :: 14
MAX_LINK_LENGTH :: 28
SPINE_THICKNESS :: 6
MIN_JOINTS :: 8
MAX_JOINTS :: 24
MIN_BODY :: 0.2
MAX_BODY :: 0.4
MIN_SPEED :: 100
MAX_SPEED :: 300
SCREEN_WIDTH :: 1200
SCREEN_HEIGHT :: 900
BORDER :: 150

Snake :: struct {
	id:     int,
	chain:  Chain,
	vel:    rl.Vector2,
	color1: rl.Color,
	color2: rl.Color,
	body:   f32,
	smooth: bool,
	birth:  f64,
	//  colors: [dynamic]rl.Color
}

snakes: map[int]^Snake

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT}) // ultimately controls max FPS
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Snakes")
	rl.SetTargetFPS(60)

	init_snakes()

	pause := false
	for !rl.WindowShouldClose() {
		if rl.IsKeyPressed(.SPACE) {
			pause = !pause
		}

		if rl.IsKeyPressed(.R) {
			init_snakes()
		}

		if pause == false {
			dt := rl.GetFrameTime()
			update(dt)
		}

		rl.BeginDrawing()
		rl.ClearBackground(BACKGROUND)
		draw()
		rl.EndDrawing()

	}
}

update :: proc(dt: f32) {
	for id, s in snakes {
		pos := s.chain.joints[0]
		pos.x += s.vel.x * dt
		pos.y += s.vel.y * dt

		//radius := joints_radius(0) * s.body
		radius: f32 = 0.0
		if pos.x - radius <= 0 {
			pos.x = radius
			s.vel.x *= -1
		} else if pos.x + radius >= SCREEN_WIDTH {
			pos.x = SCREEN_WIDTH - radius
			s.vel.x *= -1
		}

		if pos.y - radius <= 0 {
			pos.y = radius
			s.vel.y *= -1
		} else if pos.y + radius >= SCREEN_HEIGHT {
			pos.y = SCREEN_HEIGHT - radius
			s.vel.y *= -1
		}

		//s.chain.joints[0] = pos

		chain_resolve(s.chain, pos)
	}
}

draw :: proc() {
	for id, s in snakes {
		if s.smooth {
			draw_smooth(s^)
		} else {
			draw_shapes(s^)
		}
	}
}

draw_smooth :: proc(s: Snake) {
	age := rl.GetTime() - s.birth
	p := f32(age / 100)

	if p > 1.0 {
		p = 1.0
	}

	thicknesses := make([]f32, len(s.chain.joints))
	for i in 0 ..< len(s.chain.joints) {
		thicknesses[i] = joints_radius(i) * s.body * 1.25
	}

	draw_smooth_snake(
		s.chain.joints[:],
		thicknesses,
		color_to_gray(s.color1, p),
		color_to_gray(s.color2, p),
	)

	delete(thicknesses)

	// compute eyes
	rotation: f32
	head_rec: rl.Rectangle
	c := s.chain

	size := joints_radius(0) * s.body * 0.5 // eye spread
	rotation = c.angles[1] * 180 / f32(math.PI) + 45
	head_rec = rl.Rectangle {
		x      = c.joints[0].x,
		y      = c.joints[0].y,
		width  = size,
		height = size,
	}

	head_rec.x -= head_rec.width / 2
	head_rec.y -= head_rec.height / 2
	corners := get_rotated_corners(head_rec, rotation)
	r := joints_radius(0) * s.body
	for i in 0 ..< len(corners) {
		if i % 2 == 0 {
			// eyes
			rl.DrawCircleV(corners[i], r * 0.22, rl.BLACK)
			rl.DrawCircleV(corners[i], r * 0.16, rl.WHITE)
			rl.DrawCircleV(corners[i], r * 0.08, rl.BLACK)
		} else if i == 1 {
			// nose
			rl.DrawCircleV(corners[i], r * 0.22, s.color2)
		}
	}
}

draw_shapes :: proc(s: Snake) {
	chain := s.chain

	// body
	age := rl.GetTime() - s.birth
	p := f32(age / 100.0)

	if p > 1.0 {
		p = 1.0
	}

	c1 := color_to_gray(s.color1, p)
	c1.a = 153
	c2 := color_to_gray(s.color2, p)
	c2.a = 153

	for i in 1 ..< len(chain.joints) {
		col := i % 2 == 0 ? c1 : c2
		rl.DrawCircleV(chain.joints[i], joints_radius(i) * s.body, col)
	}

	rotation: f32 = 0.0
	for i in 0 ..< len(chain.joints) {
		size := joints_radius(i) * s.body * 2.0
		rotation = chain.angles[i] * 180 / f32(math.PI)
		rec := rl.Rectangle {
			x      = chain.joints[i].x,
			y      = chain.joints[i].y,
			width  = size,
			height = size,
		}

		origin := rl.Vector2{size / 2.0, size / 2.0}
		col := i % 2 == 0 ? c1 : c2
		rl.DrawRectanglePro(rec, origin, rotation, col) // s.color1)
	}

	// pointed head
	head_rec: rl.Rectangle
	for i in 0 ..< 1 {
		size := joints_radius(i) * s.body * 2.5
		rotation = chain.angles[i + 1] * 180 / f32(math.PI) + 45
		head_rec = rl.Rectangle {
			x      = chain.joints[i].x,
			y      = chain.joints[i].y,
			width  = size,
			height = size,
		}

		origin := rl.Vector2{size / 2.0, size / 2.0}
		col := i % 2 == 0 ? c1 : c2
		rl.DrawRectanglePro(head_rec, origin, rotation, col)
	}


	// head
	//rl.DrawCircleV(c.joints[0], joints_radius(0) * s.body, rl.RED)

	// spine
	spine := rl.Color{255, 255, 255, 153}
	for i in 1 ..< len(chain.joints) {
		rl.DrawLineEx(chain.joints[i - 1], chain.joints[i], SPINE_THICKNESS, spine)
		rl.DrawCircleV(chain.joints[i], joints_radius(i) * s.body * 0.25, spine)
	}

	//b brain
	rl.DrawCircleV(chain.joints[0], joints_radius(0) * s.body * 0.6, rl.Color{255, 255, 255, 204})
	rl.DrawCircleV(chain.joints[0], joints_radius(0) * s.body * 0.5, rl.Color{255, 0, 0, 153})

	// eyes
	head_rec.x -= head_rec.width / 2
	head_rec.y -= head_rec.height / 2
	corners := get_rotated_corners(head_rec, rotation)
	r := joints_radius(0)
	for i in 0 ..< len(corners) {
		if i % 2 == 0 {
			rl.DrawCircleV(corners[i], r * 0.1, rl.WHITE)
			rl.DrawCircleV(corners[i], r * 0.08, rl.BLACK)
		} else if i == 1 {
			// nose
			rl.DrawCircleV(corners[i], r * 0.15, c1) // s.color1)
		}
	}
}

init_snakes :: proc() {
	for i in 0 ..< SNAKE_COUNT {
		snake := new(Snake)
		id := i + 1
		speed := MIN_SPEED + rand.float32_range(0, MAX_SPEED - MIN_SPEED)
		angle := rand.float32_range(0, 2 * math.PI)
		body := rand.float32_range(MIN_BODY, MAX_BODY)
		links := rand.float32_range(MIN_LINK_LENGTH, MAX_LINK_LENGTH)
		joints := int(rand.float32_range(MIN_JOINTS, MAX_JOINTS))
		origin := rl.Vector2 {
			rand.float32_range(BORDER, SCREEN_WIDTH - 2.0 * BORDER),
			rand.float32_range(BORDER, SCREEN_HEIGHT - 2.0 * BORDER),
		}
		color := random_color()

		snake.id = id
		snake.vel.x = math.cos(angle) * speed
		snake.vel.y = math.sin(angle) * speed
		snake.body = body
		snake.color1 = color
		snake.color2 = get_complementary_color(color)
		snake.birth = rl.GetTime()
		snake.smooth = true // rand.float32_range(0, 2) < 1

		chain := new_chain(origin, joints, links, math.PI / 4.0)
		snake.chain = chain

		snakes[id] = snake

		chain_resolve(chain, chain.joints[0])
	}
}

random_color :: proc() -> rl.Color {
	return rl.Color{u8(rand.int_max(255)), u8(rand.int_max(255)), u8(rand.int_max(255)), 255}
}

joints_radius :: proc(i: int) -> f32 {
	r: f32 = 0
	if i == 0 {
		return MAX_RADIUS
	} else if i == 1 {
		return MAX_RADIUS * 1.08
	} else {
		m := f32(MAX_RADIUS - 10)
		r = f32(m - 2.4 * f32(i))
		if r > 5 {
			return r
		}

		return 5
	}
}
