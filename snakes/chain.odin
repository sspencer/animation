package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

TwoPi :: 2 * math.PI

Chain :: struct {
	joints:          [dynamic]rl.Vector2,
	linkSize:        f32,
	angles:          [dynamic]f32,
	angleConstraint: f32,
}

new_chain :: proc(
	origin: rl.Vector2,
	jointCount: int,
	linkSize: f32,
	angleConstraint: f32,
) -> Chain {
	chain := Chain {
		joints          = make([dynamic]rl.Vector2),
		linkSize        = linkSize,
		angles          = make([dynamic]f32),
		angleConstraint = angleConstraint,
	}

	append(&chain.joints, origin)
	append(&chain.angles, 0.0)

	for i in 1 ..< jointCount {
		v1 := chain.joints[i - 1]
		v2 := rl.Vector2{0.0, linkSize}

		append(&chain.joints, v1 + v2)
		append(&chain.angles, 0.0)
	}

	return chain
}

chain_resolve :: proc(chain: Chain, pos: rl.Vector2) {

	// The smoothing factor controls how quickly the joint moves toward the target (0.1 = 10% of the way each frame)
	smoothingFactor: f32 = 0.1
	chain.joints[0] = linalg.lerp(chain.joints[0], pos, smoothingFactor)



	v : rl.Vector2 = pos - chain.joints[0]
	chain.angles[0] = math.atan2(v.y, v.x)
	chain.joints[0] = pos

	for i in 1 ..< len(chain.joints) {
        v = chain.joints[i-1] - chain.joints[i]
        curAngle := math.atan2(v.y, v.x)
        chain.angles[i] = constrain_angle(curAngle, chain.angles[i-1], chain.angleConstraint)
        va := rl.Vector2Normalize(vector2_from_angle(chain.angles[i])) * chain.linkSize
        chain.joints[i] = chain.joints[i-1] - va
	}
}
