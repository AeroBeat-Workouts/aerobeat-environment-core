class_name AeroEnvironmentRequest
extends RefCounted

const AeroEnvironmentConstants = preload("../globals/aero_environment_constants.gd")

var request_id: String = ""
var kind: String = ""
var asset_path: String = ""
var config_path: String = ""
var display_mode: String = AeroEnvironmentConstants.DISPLAY_MODE_COVER
var context: Dictionary = {}
var metadata: Dictionary = {}

func _init(data: Dictionary = {}) -> void:
	apply_dict(data)

static func from_dict(data: Dictionary):
	return new(data)

func apply_dict(data: Dictionary):
	request_id = String(data.get("request_id", "")).strip_edges()
	kind = AeroEnvironmentConstants.normalize_kind(String(data.get("kind", "")))
	asset_path = String(data.get("asset_path", "")).strip_edges()
	config_path = String(data.get("config_path", "")).strip_edges()
	display_mode = AeroEnvironmentConstants.normalize_display_mode(String(data.get("display_mode", AeroEnvironmentConstants.DISPLAY_MODE_COVER)))
	context = data.get("context", {}) if data.get("context", {}) is Dictionary else {}
	metadata = Dictionary(data.get("metadata", {})) if data.get("metadata", {}) is Dictionary else {}
	return self

func duplicate_request():
	return new(to_dict())

func to_dict() -> Dictionary:
	return {
		"request_id": request_id,
		"kind": kind,
		"asset_path": asset_path,
		"config_path": config_path,
		"display_mode": display_mode,
		"context": context.duplicate(true),
		"metadata": metadata.duplicate(true),
	}
