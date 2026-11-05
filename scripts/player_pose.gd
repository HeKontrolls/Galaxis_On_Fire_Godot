extends RefCounted
const Melee = preload("res://scripts/melee_weapons.gd")


static func shoulder(at: Vector2, facing: int) -> Vector2:
	return at + Vector2(8 + facing * 3, 7)


static func behind_body(at: Vector2, hand: Vector2, facing: int) -> bool:
	var offset := hand - shoulder(at, facing)
	return offset.y < -4.0 and offset.x * facing < 3.0


static func arm_transform(start: Vector2, hand: Vector2, facing: int) -> Transform2D:
	# One native sprite: shoulder (4,1), fist grip (4,17). No elbow seam.
	var delta := hand - start
	return Transform2D(delta.angle() - PI * 0.5, Vector2(facing, delta.length() / 16.0), 0, start)


static func tool(at: Vector2, aim: Vector2, facing: int, active: bool, progress: float, item: String, watering: bool) -> Transform2D:
	if Melee.has_weapon(item) and Melee.WEAPONS[item].motion == "thrust":
		return Melee.pose(at, aim.normalized(), facing, active, progress)
	var theta := atan2(aim.y, absf(aim.x))
	var arm_angle := theta
	var length := 12.0
	var rotation := theta + 1.2
	if item == "Watering Can":
		arm_angle = theta * 0.35
		length = 15.0
		var tilt := smoothstep(0.02, 0.22, progress) * (1.0 - smoothstep(0.77, 1.0, progress)) if active and watering else 0.0
		rotation = lerpf(0.08, 1.18, tilt) + theta * 0.12
	elif item == "Hand":
		length = 10.0 + (sin(progress * PI) * 5.0 if active else 0.0)
	elif active:
		length = 14.5
		if progress < 0.16:
			arm_angle = theta + lerpf(-1.3, -1.95, smoothstep(0.0, 0.16, progress))
		elif progress < 0.72:
			arm_angle = theta + lerpf(-1.95, 1.05, smoothstep(0.16, 0.72, progress))
		else:
			arm_angle = theta + lerpf(1.05, 0.0, smoothstep(0.72, 1.0, progress))
		var recovery := smoothstep(0.72, 1.0, progress)
		length = lerpf(length, 12.0, recovery)
		rotation = lerp_angle(arm_angle + PI * 0.5, theta + 1.2, recovery)
	var hand := shoulder(at, facing) + Vector2(cos(arm_angle) * facing, sin(arm_angle)) * length
	return Transform2D(rotation * facing, Vector2(facing * 0.82, 0.82), 0.0, hand)
