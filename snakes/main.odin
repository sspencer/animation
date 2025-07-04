package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

BACKGROUND :: rl.Color{ 43, 60, 80, 255 }
SNAKE_COUNT :: 10
MAX_RADIUS :: 65
MIN_LINK_LENGTH :: 14
MAX_LINK_LENGTH :: 28
COLLISION_TIME :: 1.0
SPINE_THICKNESS :: 6
MIN_JOINTS :: 8
MAX_JOINTS :: 24
MIN_BODY :: 0.2
MAX_BODY :: 0.4
MIN_SPEED :: 75
MAX_SPEED :: 300
SCREEN_WIDTH :: 1200
SCREEN_HEIGHT :: 900
BORDER :: 150
THICKNESS :: 1.35
SHRINKAGE :: 0.65

Snake :: struct {
    id: int,
    chain: Chain,
    vel: rl.Vector2,
    color1: rl.Color,
    color2: rl.Color,
    body: f32,
    birth: f64,
    collision: f32
}

snakes: map[int]^Snake

main :: proc() {
    rl.SetConfigFlags({ .VSYNC_HINT }) // ultimately controls max FPS
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
    check_collisions(dt)
    update_positions(dt)
}

update_positions :: proc(dt: f32) {
    for id, s in snakes {
        pos := s.chain.joints[0]

        vel_change := rand.float32_range(0, 100)
        delta: f32 = 30.0
        if vel_change < 3 {
            n := rand.int_max(100)
            if n < 40 {
                s.vel.x += rand.float32_range(-delta, delta)
            } else if n < 80 {
                s.vel.y += rand.float32_range(-delta, delta)
            } else {
                s.vel.x += rand.float32_range(-delta, delta)
                s.vel.y += rand.float32_range(-delta, delta)
            }
            //fmt.printf("snake %d speed change to %v\n", id, s.vel)
        }

        pos.x += s.vel.x * dt
        pos.y += s.vel.y * dt

        //radius := joints_radius(0) * s.body
        radius : f32 = 0.0
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

        s.vel.x = clamp_vel(s.vel.x)
        s.vel.y = clamp_vel(s.vel.y)

        chain_resolve(s.chain, pos)
    }
}

clamp_vel :: proc(v: f32) -> f32 {
    sgn: f32 = v < 0 ? -1.0 : 1.0
    return clamp(math.abs(v), MIN_SPEED, MAX_SPEED) * sgn
}

check_collisions :: proc(dt: f32) {
    arr := make([]^Snake, len(snakes))

    i := 0
    for _, s in snakes {
        arr[i] = s
        i += 1
    }

    for i in 0 ..< len(arr) - 1 {
        for j in i + 1 ..< len(arr) {
            s1 := arr[i]
            s2 := arr[j]
            r1 := radius(0) * s1.body * SHRINKAGE // head of smooth snake is smaller than expected radius
            r2 := radius(0) * s2.body * SHRINKAGE

            pos1 := s1.chain.joints[0]
            pos1.x += s1.vel.x * dt
            pos1.y += s1.vel.y * dt
            pos2 := s2.chain.joints[0]
            pos2.x += s2.vel.x * dt
            pos2.y += s2.vel.y * dt

            dx := pos2.x - pos1.x
            dy := pos2.y - pos1.y

            distance := math.sqrt(dx * dx + dy * dy)

            // Check if collision occurred

            if distance < (r1 + r2) && distance > 0 {
                t := f32(rl.GetTime())
                // max sure snakes have time between collisions to separate
                if t - s1.collision > COLLISION_TIME && t - s2.collision > COLLISION_TIME {
                    s1.collision = t
                    s2.collision = t
                    // faster velocity wins
                    //v1 := math.sqrt(s1.vel.x*s1.vel.x + s1.vel.y*s1.vel.y)
                    //v2 := math.sqrt(s2.vel.x*s2.vel.x + s2.vel.y*s2.vel.y)

                    resolve_collision_with_mass(s1, s2, r1, r2, dx, dy, distance)

                    s1.vel.x += rand.float32_range(-20, 20)
                    s1.vel.y += rand.float32_range(-20, 20)
                    s2.vel.x += rand.float32_range(-20, 20)
                    s2.vel.y += rand.float32_range(-20, 20)
                }
            }
        }
    }

    delete(arr)
}

resolve_collision_with_mass :: proc(s1, s2: ^Snake, r1, r2, dx, dy, distance: f32) {
// Normalize the collision vector
    nx := dx / distance
    ny := dy / distance

    // Calculate masses based on radius + body length
    // Mass proportional to area: mass = π * r²
    mass1 := f32(math.PI) * r1 * r1 + (f32(len(s1.chain.joints)) * s1.chain.linkSize * s1.body * 3.0)
    mass2 := f32(math.PI) * r2 * r2 + (f32(len(s2.chain.joints)) * s2.chain.linkSize * s2.body * 3.0)
    //fmt.printf("m1=%f, m2=%f\n", mass1, mass2)
    total_mass := mass1 + mass2

    // Separate the balls to prevent overlap based on mass ratio
    // Heavier balls move less during separation
    overlap := r1 + r2 - distance
    separation1 := overlap * (mass2 / total_mass)
    separation2 := overlap * (mass1 / total_mass)

    s1.chain.joints[0].x -= nx * separation1
    s1.chain.joints[0].y -= ny * separation1
    s2.chain.joints[0].x -= nx * separation2
    s2.chain.joints[0].y -= ny * separation2

    // Calculate relative velocity
    rel_vel_x := s2.vel.x - s1.vel.x
    rel_vel_y := s2.vel.y - s1.vel.y

    // Calculate relative velocity along collision normal
    speed := rel_vel_x * nx + rel_vel_y * ny

    // Do not resolve if velocities are separating
    if speed > 0 {
        return
    }

    // Calculate restitution (bounciness) - perfect elastic collision
    restitution := 4.0

    // Calculate impulse scalar using proper mass formula
    impulse := f32(1.0 + restitution) * speed / (1.0 / mass1 + 1.0 / mass2)

    // Apply impulse to velocities (inverse mass relationship)
    impulse_x := impulse * nx
    impulse_y := impulse * ny

    s1.vel.x += impulse_x / mass1
    s1.vel.y += impulse_y / mass1
    s2.vel.y -= impulse_x / mass2
    s2.vel.y -= impulse_y / mass2
}

draw :: proc() {
    for id, s in snakes {
        age := rl.GetTime() - s.birth
        p := f32(age / 100)

        if p > 1.0 {
            p = 1.0
        }

        thicknesses := make([]f32, len(s.chain.joints))
        for i in 0 ..< len(s.chain.joints) {
            thicknesses[i] = radius(i) * s.body * THICKNESS
        }

        draw_smooth_snake(
        s.chain.joints[:],
        thicknesses,
        s.color1, // color_to_gray(s.color1, p),
        s.color2, // color_to_gray(s.color2, p),
        )

        delete(thicknesses)

        // compute eyes
        rotation: f32
        head_rec: rl.Rectangle
        c := s.chain

        size := radius(0) * s.body * 0.5 // eye spread
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
        r := radius(0) * s.body
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

        t := f32(rl.GetTime())

        if s.collision > 0 && t - s.collision < COLLISION_TIME {
            n := int((t - s.collision) * 10.0)
            if n % 4 < 2 {
                rl.DrawCircleV(c.joints[0], radius(0) * s.body * (SHRINKAGE + 0.1) , rl.Color{ 255, 0, 0, 153 })
            } else {
                rl.DrawCircleV(c.joints[0], radius(0) * s.body * (SHRINKAGE + 0.1), rl.Color{ 255, 203, 0, 153 })
            }
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

        color1 := random_color()
        color2 := random_color() // get_complementary_color(color)
        snake.id = id
        snake.vel.x = math.cos(angle) * speed
        snake.vel.y = math.sin(angle) * speed
        fmt.printf("init snake %d angle=%f, velocity %v\n", id, angle, snake.vel)

        snake.body = body
        snake.color1 = color1
        snake.color2 = color2
        snake.birth = rl.GetTime()

        chain := new_chain(origin, joints, links, math.PI / 4.0)
        snake.chain = chain

        snakes[id] = snake

        chain_resolve(chain, chain.joints[0])
    }
}

random_color :: proc() -> rl.Color {
    colors := []rl.Color{
    rl.YELLOW,
    rl.GOLD,
    rl.ORANGE,
    rl.PINK,
    rl.RED,
    rl.MAROON,
    rl.GREEN,
    rl.LIME,
    rl.DARKGREEN,
    rl.SKYBLUE,
    rl.BLUE,
    rl.DARKBLUE,
    rl.PURPLE,
    rl.VIOLET,
    rl.DARKPURPLE
    }

    return colors[rand.int_max(len(colors))]
    //return rl.Color{ u8(rand.int_max(255)), u8(rand.int_max(255)), u8(rand.int_max(255)), 255 }
}

radius :: proc(i: int) -> f32 {
    r : f32 = 0
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
