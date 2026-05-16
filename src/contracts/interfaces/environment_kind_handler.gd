class_name AeroEnvironmentKindHandler
extends "environment_fulfillment.gd"

const AeroEnvironmentConstants = preload("../globals/aero_environment_constants.gd")

var supported_kind: String = ""

func _init(kind: String = "") -> void:
	supported_kind = AeroEnvironmentConstants.normalize_kind(kind)

func get_handler_name() -> String:
	return supported_kind

func supports_kind(kind: String) -> bool:
	return not supported_kind.is_empty() and AeroEnvironmentConstants.normalize_kind(kind) == supported_kind
