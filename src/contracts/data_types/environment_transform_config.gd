class_name AeroEnvironmentTransformConfig
extends RefCounted

var position: Vector3 = Vector3.ZERO
var rotation_degrees: Vector3 = Vector3.ZERO
var scale: Vector3 = Vector3.ONE

func _init(data: Dictionary = {}) -> void:
	apply_dict(data)

static func from_dict(data: Dictionary):
	return new(data)

func apply_dict(data: Dictionary):
	position = _variant_to_vector3(data.get("position", Vector3.ZERO), Vector3.ZERO)
	rotation_degrees = _variant_to_vector3(data.get("rotation_degrees", Vector3.ZERO), Vector3.ZERO)
	scale = _variant_to_vector3(data.get("scale", Vector3.ONE), Vector3.ONE)
	return self

func to_dict() -> Dictionary:
	return {
		"position": [position.x, position.y, position.z],
		"rotation_degrees": [rotation_degrees.x, rotation_degrees.y, rotation_degrees.z],
		"scale": [scale.x, scale.y, scale.z],
	}

static func _variant_to_vector3(value: Variant, default_value: Vector3) -> Vector3:
	if value is Vector3:
		return value
	if value is Array:
		var array_value: Array = value
		if array_value.size() >= 3:
			return Vector3(float(array_value[0]), float(array_value[1]), float(array_value[2]))
	if value is Dictionary:
		var dict_value: Dictionary = value
		return Vector3(
			float(dict_value.get("x", default_value.x)),
			float(dict_value.get("y", default_value.y)),
			float(dict_value.get("z", default_value.z))
		)
	return default_value
