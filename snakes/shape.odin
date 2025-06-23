package main

import "core:math"
import rl "vendor:raylib"

// Evaluate a Catmull-Rom spline at parameter t (0 to 1) for four control points
catmull_rom :: proc(p0, p1, p2, p3: rl.Vector2, t: f32) -> rl.Vector2 {
    t2 := t * t
    t3 := t2 * t
    return rl.Vector2 {
        0.5 *
        ((2.0 * p1.x) +
        (-p0.x + p2.x) * t +
        (2.0 * p0.x - 5.0 * p1.x + 4.0 * p2.x - p3.x) * t2 +
        (-p0.x + 3.0 * p1.x - 3.0 * p2.x + p3.x) * t3),
        0.5 *
        ((2.0 * p1.y) +
        (-p0.y + p2.y) * t +
        (2.0 * p0.y - 5.0 * p1.y + 4.0 * p2.y - p3.y) * t2 +
        (-p0.y + 3.0 * p1.y - 3.0 * p2.y + p3.y) * t3),
    }
}

// Generate interpolated points and thicknesses along a Catmull-Rom spline
interpolate_snake :: proc(points: []rl.Vector2, thicknesses: []f32, segments_per_point: int) -> ([]rl.Vector2, []f32) {
    if len(points) < 2 || len(points) != len(thicknesses) {
        return nil, nil
    }

    // Calculate total points: one per segment plus control points
    total_points := (len(points) - 1) * segments_per_point + 1
    result_points := make([]rl.Vector2, total_points)
    result_thicknesses := make([]f32, total_points)

    idx := 0
    for i in 0 ..< len(points) - 1 {
    // Control points for position
        p0 := i == 0 ? points[0] : points[i - 1]
        p1 := points[i]
        p2 := points[i + 1]
        p3 := i + 2 < len(points) ? points[i + 2] : points[i + 1]

        // Control thicknesses (linear interpolation between t1 and t2)
        t1 := thicknesses[i]
        t2 := thicknesses[i + 1]

        // Generate points for this segment
        for j in 0 ..< segments_per_point {
            t := f32(j) / f32(segments_per_point)
            result_points[idx] = catmull_rom(p0, p1, p2, p3, t)
            // Linear interpolation for thickness
            result_thicknesses[idx] = t1 + (t2 - t1) * t
            // Clamp to prevent zero or negative thickness
            result_thicknesses[idx] = max(result_thicknesses[idx], 0.1)
            idx += 1
        }
    }

    // Add final point
    result_points[idx] = points[len(points) - 1]
    result_thicknesses[idx] = thicknesses[len(thicknesses) - 1]
    result_thicknesses[idx] = max(result_thicknesses[idx], 0.1)

    return result_points, result_thicknesses
}

// Draw a thick snake body with smooth curves and variable thickness
draw_smooth_snake :: proc(points: []rl.Vector2, thicknesses: []f32, color1, color2: rl.Color) {
    if len(points) < 2 || len(points) != len(thicknesses) {
        return
    }

    // Interpolate points and thicknesses for smoothness
    segments_per_point := 9 // was 10,
    interp_points, interp_thicknesses := interpolate_snake(
    points,
    thicknesses,
    segments_per_point,
    )
    defer delete(interp_points)
    defer delete(interp_thicknesses)

    // Compute offset points for variable thickness
    offset_points := make([][2]rl.Vector2, len(interp_points))
    defer delete(offset_points)

    for i in 0 ..< len(interp_points) {
    // Compute tangent (central difference for stability)
        tangent: rl.Vector2
        if i == 0 {
            tangent = interp_points[1] - interp_points[0]
        } else if i == len(interp_points) - 1 {
            tangent = interp_points[i] - interp_points[i - 1]
        } else {
            tangent = (interp_points[i + 1] - interp_points[i - 1]) * 0.5
        }

        // Normalize tangent
        len := math.sqrt(tangent.x * tangent.x + tangent.y * tangent.y)
        if len > 0 {
            tangent.x /= len
            tangent.y /= len
        }

        // Perpendicular vector (rotate 90 degrees, ensure consistent direction)
        perp := rl.Vector2{ -tangent.y, tangent.x }

        // Compute right and left offset points
        half_thickness := interp_thicknesses[i] / 2.0
        offset_points[i][0] = interp_points[i] + perp * half_thickness // Right
        offset_points[i][1] = interp_points[i] - perp * half_thickness // Left
    }

    // Draw body using individual triangles for each quad
    for i in 0 ..< len(interp_points) - 1 {
    // Define quad vertices: right_i, left_i, right_i+1, left_i+1
        r0 := offset_points[i][0] // Right i
        l0 := offset_points[i][1] // Left i
        r1 := offset_points[i + 1][0] // Right i+1
        l1 := offset_points[i + 1][1] // Left i+1

        // Draw two triangles per quad, ensuring counter-clockwise winding
        c: rl.Color
        if i % 8 < 4  || i < 8 {
            c = color1
        } else {
            c = color2
        }
        // Triangle 1: r0, r1, l0
        rl.DrawTriangle(r0, r1, l0, c)
        // Triangle 2: r1, l1, l0
        rl.DrawTriangle(r1, l1, l0, c)
    }

    // Debug: Draw outline of body to confirm offset points
//    for i in 0 ..< len(interp_points) - 1 {
//        rl.DrawLineV(offset_points[i][0], offset_points[i + 1][0], rl.WHITE)
//        rl.DrawLineV(offset_points[i][1], offset_points[i + 1][1], rl.WHITE)
//    }

    // Draw rounded caps at start and end
    rl.DrawCircleV(interp_points[0], interp_thicknesses[0] / 2.0, color1)
    rl.DrawCircleV(
        interp_points[len(interp_points) - 1],
        interp_thicknesses[len(interp_points) - 1] / 2.5,
        color1,
    )
}

