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
	var transform_dict: Dictionary = {}
	if data.get("transform", {}) is Dictionary:
		transform_dict = Dictionary(data.get("transform", {})).duplicate(true)
	elif data.has("position") or data.has("rotation_degrees") or data.has("scale"):
		transform_dict = {
			"position": data.get("position", Vector3.ZERO),
			"rotation_degrees": data.get("rotation_degrees", Vector3.ZERO),
			"scale": data.get("scale", Vector3.ONE),
		}
	transform = AeroEnvironmentTransformConfig.from_dict(transform_dict)

	var media_dict: Dictionary = {}
	if data.get("media", {}) is Dictionary:
		media_dict = Dictionary(data.get("media", {})).duplicate(true)
	elif data.has("fit_mode") or data.has("display_mode"):
		media_dict = {
			"fit_mode": data.get("fit_mode", data.get("display_mode", "")),
		}
	media = AeroEnvironmentMediaConfig.from_dict(media_dict)

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
