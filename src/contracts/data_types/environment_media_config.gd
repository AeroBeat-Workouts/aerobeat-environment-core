class_name AeroEnvironmentMediaConfig
extends RefCounted

const AeroEnvironmentConstants = preload("../globals/aero_environment_constants.gd")

var fit_mode: String = AeroEnvironmentConstants.FIT_MODE_COVER

func _init(data: Dictionary = {}) -> void:
	apply_dict(data)

static func from_dict(data: Dictionary):
	return new(data)

func apply_dict(data: Dictionary):
	fit_mode = AeroEnvironmentConstants.normalize_fit_mode(String(data.get("fit_mode", AeroEnvironmentConstants.FIT_MODE_COVER)))
	return self

func to_dict() -> Dictionary:
	return {
		"fit_mode": fit_mode,
	}
