class_name AeroEnvironmentConfigHelper
extends RefCounted

const AeroEnvironmentConfig = preload("../data_types/environment_config.gd")

static func parse_config_dict(config: Dictionary) -> Dictionary:
	return {
		"ok": true,
		"config": AeroEnvironmentConfig.from_dict(config),
	}

static func apply_config_dict(config: Dictionary, target: Node) -> Dictionary:
	var parse_result := parse_config_dict(config)
	return apply_config_model(parse_result["config"], target)

static func apply_config_model(config: Variant, target: Node) -> Dictionary:
	if not (target is Node3D):
		return {
			"ok": false,
			"message": "Environment config can only be applied to Node3D content.",
		}
	var node_3d := target as Node3D
	node_3d.position = config.transform.position
	node_3d.rotation_degrees = config.transform.rotation_degrees
	node_3d.scale = config.transform.scale
	return {
		"ok": true,
		"config": config,
	}

static func variant_to_vector3(value: Variant, default_value: Vector3) -> Vector3:
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
