package main

import "core:math"
import rl "vendor:raylib"

// Convert RGB to HSV
rgb_to_hsv :: proc(r, g, b: f32) -> (h, s, v: f32) {
	max_val := max(r, g, b)
	min_val := min(r, g, b)
	delta := max_val - min_val

	// Value (brightness)
	v = max_val

	// Saturation
	if max_val == 0 {
		s = 0
	} else {
		s = delta / max_val
	}

	// Hue
	if delta == 0 {
		h = 0 // Gray, no hue
	} else if max_val == r {
		h = 60 * (((g - b) / delta) + (g < b ? 6 : 0))
	} else if max_val == g {
		h = 60 * (((b - r) / delta) + 2)
	} else { 	// max_val == b
		h = 60 * (((r - g) / delta) + 4)
	}

	return h, s, v
}

// Convert HSV to RGB
hsv_to_rgb :: proc(h, s, v: f32) -> (r, g, b: f32) {
	if s == 0 {
		// Gray
		return v, v, v
	}

	h_sector := h / 60
	sector := int(math.floor(h_sector))
	fractional := h_sector - f32(sector)

	p := v * (1 - s)
	q := v * (1 - s * fractional)
	t := v * (1 - s * (1 - fractional))

	switch sector {
	case 0:
		return v, t, p
	case 1:
		return q, v, p
	case 2:
		return p, v, t
	case 3:
		return p, q, v
	case 4:
		return t, p, v
	case 5, 6:
		return v, p, q
	}

	return v, p, q // fallback
}

// Get complementary color using HSV method (most accurate)
get_complementary_color :: proc(color: rl.Color) -> rl.Color {
	// Convert to 0-1 range
	r := f32(color.r) / 255.0
	g := f32(color.g) / 255.0
	b := f32(color.b) / 255.0

	// Convert to HSV
	h, s, v := rgb_to_hsv(r, g, b)

	// Rotate hue by 180 degrees for complement
	comp_h := h + 180
	if comp_h >= 360 {
		comp_h -= 360
	}

	// Convert back to RGB
	comp_r, comp_g, comp_b := hsv_to_rgb(comp_h, s, v)

	// Convert back to 0-255 range and create color
	return rl.Color {
		u8(comp_r * 255),
		u8(comp_g * 255),
		u8(comp_b * 255),
		color.a, // Keep original alpha
	}
}

// Alternative: Rotational method (good balance of speed and accuracy)
get_complementary_color_rotational :: proc(color: rl.Color) -> rl.Color {
	max_val := max(color.r, color.g, color.b)
	min_val := min(color.r, color.g, color.b)
	sum := max_val + min_val

	return rl.Color {
		sum - color.r,
		sum - color.g,
		sum - color.b,
		color.a, // Keep original alpha
	}
}


// Convert a color to gray using luminance-based method with percentage control
// percentage: 0.0 = original color, 1.0 = full grayscale
color_to_gray :: proc(color: rl.Color, percentage: f32) -> rl.Color {
	// Clamp percentage to valid range
	pct := math.clamp(percentage, 0.0, 1.0)

	// Calculate luminance using standard weights (perceived brightness)
	// These weights account for human eye sensitivity to different colors
	luminance := 0.299 * f32(color.r) + 0.587 * f32(color.g) + 0.114 * f32(color.b)
	gray_value := u8(luminance)

	// Interpolate between original color and gray
	new_r := u8(f32(color.r) * (1.0 - pct) + f32(gray_value) * pct)
	new_g := u8(f32(color.g) * (1.0 - pct) + f32(gray_value) * pct)
	new_b := u8(f32(color.b) * (1.0 - pct) + f32(gray_value) * pct)

	return rl.Color {
		new_r,
		new_g,
		new_b,
		color.a, // Preserve alpha
	}
}

// Alternative method using desaturation (HSV-based approach)
color_to_gray_desaturate :: proc(color: rl.Color, percentage: f32) -> rl.Color {
	pct := math.clamp(percentage, 0.0, 1.0)

	// Convert to 0-1 range
	r := f32(color.r) / 255.0
	g := f32(color.g) / 255.0
	b := f32(color.b) / 255.0

	// Simple HSV conversion for saturation adjustment
	max_val := max(r, g, b)
	min_val := min(r, g, b)

	// Reduce saturation by moving towards the average
	avg := (max_val + min_val) / 2.0

	new_r := r + (avg - r) * pct
	new_g := g + (avg - g) * pct
	new_b := b + (avg - b) * pct

	return rl.Color{u8(new_r * 255), u8(new_g * 255), u8(new_b * 255), color.a}
}


// Example usage
colormain :: proc() {
	// Test colors
	test_colors := []rl.Color {
		rl.RED,
		rl.GREEN,
		rl.BLUE,
		rl.YELLOW,
		rl.MAGENTA,
		{128, 64, 192, 255}, // Custom purple
	}

	for color in test_colors {
		comp_hsv := get_complementary_color(color)
		comp_rot := get_complementary_color_rotational(color)

		// Print results (would need fmt import for actual printing)
		// fmt.printf("Original: RGB(%d, %d, %d)\n", color.r, color.g, color.b)
		// fmt.printf("HSV Complement: RGB(%d, %d, %d)\n", comp_hsv.r, comp_hsv.g, comp_hsv.b)
		// fmt.printf("Simple Complement: RGB(%d, %d, %d)\n", comp_simple.r, comp_simple.g, comp_simple.b)
		// fmt.printf("Rotational Complement: RGB(%d, %d, %d)\n\n", comp_rot.r, comp_rot.g, comp_rot.b)
	}

	// Test different percentages
	percentages := []f32{0.0, 0.25, 0.5, 0.75, 1.0}

	for color in test_colors {
		// Uncomment these lines if you want to see the output
		// (requires importing "core:fmt")

		// fmt.printf("Original: RGB(%d, %d, %d)\n", color.r, color.g, color.b)

		// for pct in percentages {
		//     gray_color := color_to_gray(color, pct)
		//     fmt.printf("  %.0f%% gray: RGB(%d, %d, %d)\n",
		//                pct * 100, gray_color.r, gray_color.g, gray_color.b)
		// }
		// fmt.println()
	}

}
