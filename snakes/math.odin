package main

import rl "vendor:raylib"
import "core:math"

// Compute the four corners of a rotated rectangle
get_rotated_corners :: proc(rect: rl.Rectangle, rotation: f32) -> [4]rl.Vector2 {
    // Compute center of the rectangle
    center := rl.Vector2{
        rect.x + rect.width / 2.0,
        rect.y + rect.height / 2.0,
    }

    // Convert rotation to radians
    theta := rotation * math.PI / 180.0
    cos_theta := math.cos(theta)
    sin_theta := math.sin(theta)

    // Half dimensions
    half_w := rect.width / 2.0
    half_h := rect.height / 2.0

    // Original unrotated corners relative to top-left
    corners: [4]rl.Vector2
    corners[0] = rl.Vector2{rect.x, rect.y}                    // Top-left
    corners[1] = rl.Vector2{rect.x + rect.width, rect.y}       // Top-right
    corners[2] = rl.Vector2{rect.x + rect.width, rect.y + rect.height} // Bottom-right
    corners[3] = rl.Vector2{rect.x, rect.y + rect.height}      // Bottom-left

    // Rotate each corner around the center
    rotated_corners: [4]rl.Vector2
    for i in 0..<4 {
        // Translate corner to origin (relative to center)
        x := corners[i].x - center.x
        y := corners[i].y - center.y

        // Apply rotation
        rotated_x := x * cos_theta - y * sin_theta
        rotated_y := x * sin_theta + y * cos_theta

        // Translate back to center
        rotated_corners[i] = rl.Vector2{
            center.x + rotated_x,
            center.y + rotated_y,
        }
    }

    return rotated_corners
}


vector2_from_angle :: proc(angle: f32) -> rl.Vector2 {
    return rl.Vector2{math.cos(angle), math.sin(angle)}
}

// Constrain the angle to be within a certain range of the anchor
constrain_angle :: proc(angle, anchor, constraint: f32) -> f32 {
    if math.abs(relative_angle_diff(angle, anchor)) <= constraint {
        return simplify_angle(angle)
    }

    if relative_angle_diff(angle, anchor) > constraint {
        return simplify_angle(anchor - constraint)
    }

    return simplify_angle(anchor + constraint)
}

// Compute the radians needed to turn the angle to match the anchor
relative_angle_diff :: proc(angle, anchor: f32) -> f32 {
    angle := simplify_angle(angle + math.PI - anchor)
    anchor := f32(math.PI)
    return anchor - angle
}

// Simplify the angle to be in the range [0, 2pi)
simplify_angle :: proc(angle: f32) -> f32 {
    angle := angle
    for angle >= TwoPi {
        angle -= TwoPi
    }

    for angle < 0 {
        angle += TwoPi
    }

    return angle
}
