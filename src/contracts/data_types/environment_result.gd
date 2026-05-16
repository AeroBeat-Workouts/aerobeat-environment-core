class_name AeroEnvironmentResult
extends RefCounted

const AeroEnvironmentConstants = preload("../globals/aero_environment_constants.gd")

var ok: bool = true
var request_id: String = ""
var kind: String = ""
var asset_path: String = ""
var config_path: String = ""
var format: String = ""
var config_applied: bool = false
var metadata: Dictionary = {}
var details: Dictionary = {}

func _init(data: Dictionary = {}) -> void:
	apply_dict(data)

static func from_dict(data: Dictionary):
	return new(data)

func apply_dict(data: Dictionary):
	ok = bool(data.get("ok", true))
	request_id = String(data.get("request_id", "")).strip_edges()
	kind = AeroEnvironmentConstants.normalize_kind(String(data.get("kind", "")))
	asset_path = String(data.get("asset_path", "")).strip_edges()
	config_path = String(data.get("config_path", "")).strip_edges()
	format = String(data.get("format", "")).strip_edges().to_lower()
	config_applied = bool(data.get("config_applied", false))
	metadata = Dictionary(data.get("metadata", {})) if data.get("metadata", {}) is Dictionary else {}
	details = Dictionary(data.get("details", {})) if data.get("details", {}) is Dictionary else {}
	return self

func to_dict() -> Dictionary:
	return {
		"ok": ok,
		"request_id": request_id,
		"kind": kind,
		"asset_path": asset_path,
		"config_path": config_path,
		"format": format,
		"config_applied": config_applied,
		"metadata": metadata.duplicate(true),
		"details": details.duplicate(true),
	}
