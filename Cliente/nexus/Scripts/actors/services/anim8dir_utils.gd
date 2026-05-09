class_name Anim8DirUtils
extends RefCounted

static func direction_suffix_from_vector(v: Vector2, last_suffix: StringName) -> StringName:
	if v.length_squared() < 0.0001:
		return last_suffix

	var deg: float = rad_to_deg(atan2(v.y, v.x))
	if deg >= -22.5 and deg < 22.5:
		return &"L"
	if deg >= 22.5 and deg < 67.5:
		return &"SE"
	if deg >= 67.5 and deg < 112.5:
		return &"S"
	if deg >= 112.5 and deg < 157.5:
		return &"SO"
	if deg >= 157.5 or deg < -157.5:
		return &"O"
	if deg >= -157.5 and deg < -112.5:
		return &"NO"
	if deg >= -112.5 and deg < -67.5:
		return &"N"
	if deg >= -67.5 and deg < -22.5:
		return &"NE"
	return last_suffix


static func direction_vector_from_suffix(suffix: StringName) -> Vector2:
	match suffix:
		&"L":
			return Vector2(1.0, 0.0)
		&"SE":
			return Vector2(0.70710677, 0.70710677)
		&"S":
			return Vector2(0.0, 1.0)
		&"SO":
			return Vector2(-0.70710677, 0.70710677)
		&"O":
			return Vector2(-1.0, 0.0)
		&"NO":
			return Vector2(-0.70710677, -0.70710677)
		&"N":
			return Vector2(0.0, -1.0)
		&"NE":
			return Vector2(0.70710677, -0.70710677)
		_:
			return Vector2(0.0, 1.0)
