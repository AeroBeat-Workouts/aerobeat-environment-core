class_name AeroEnvironmentConfig
extends RefCounted

const AeroEnvironmentTransformConfig = preload("environment_transform_config.gd")
const AeroEnvironmentMediaConfig = preload("environment_media_config.gd")

var transform: AeroEnvironmentTransformConfig = AeroEnvironmentTransformConfig.new()
var media: AeroEnvironmentMediaConfig = AeroEnvironmentMediaConfig.new()
var extras: Dictionary = {}

func _init(data: Dictionary = {}) -> void:
	apply_dict(data)

static func from_dict(data: Dictionary):
	return new(data)

func apply_dict(data: Dictionary):
	var transform_payload: Dictionary = {}
	if data.get("transform", null) is Dictionary:
		transform_payload = Dictionary(data.get("transform", {}))
	elif data.has("position") or data.has("rotation_degrees") or data.has("scale"):
		transform_payload = {
			"position": data.get("position", Vector3.ZERO),
			"rotation_degrees": data.get("rotation_degrees", Vector3.ZERO),
			"scale": data.get("scale", Vector3.ONE),
		}
	transform = AeroEnvironmentTransformConfig.from_dict(transform_payload)

	var media_payload: Dictionary = {}
	if data.get("media", null) is Dictionary:
		media_payload = Dictionary(data.get("media", {}))
	elif data.has("fit_mode") or data.has("display_mode"):
		media_payload = {
			"fit_mode": data.get("fit_mode", data.get("display_mode", "cover")),
		}
	media = AeroEnvironmentMediaConfig.from_dict(media_payload)

	extras = data.duplicate(true)
	extras.erase("transform")
	extras.erase("media")
	extras.erase("position")
	extras.erase("rotation_degrees")
	extras.erase("scale")
	extras.erase("fit_mode")
	extras.erase("display_mode")
	return self

func to_dict() -> Dictionary:
	var data := extras.duplicate(true)
	data["transform"] = transform.to_dict()
	data["media"] = media.to_dict()
	return data
