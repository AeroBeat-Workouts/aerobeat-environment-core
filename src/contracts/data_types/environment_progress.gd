class_name AeroEnvironmentProgress
extends RefCounted

const AeroEnvironmentConstants = preload("../globals/aero_environment_constants.gd")

var request_id: String = ""
var kind: String = ""
var asset_path: String = ""
var status: String = AeroEnvironmentConstants.STATUS_RESOLVING
var progress: float = 0.0
var message: String = ""
var metadata: Dictionary = {}

func _init(data: Dictionary = {}) -> void:
	apply_dict(data)

static func from_dict(data: Dictionary):
	return new(data)

func apply_dict(data: Dictionary):
	request_id = String(data.get("request_id", "")).strip_edges()
	kind = AeroEnvironmentConstants.normalize_kind(String(data.get("kind", "")))
	asset_path = String(data.get("asset_path", "")).strip_edges()
	status = String(data.get("status", AeroEnvironmentConstants.STATUS_RESOLVING)).strip_edges().to_lower()
	progress = clampf(float(data.get("progress", 0.0)), 0.0, 1.0)
	message = String(data.get("message", "")).strip_edges()
	metadata = Dictionary(data.get("metadata", {})) if data.get("metadata", {}) is Dictionary else {}
	return self

func to_dict() -> Dictionary:
	return {
		"request_id": request_id,
		"kind": kind,
		"asset_path": asset_path,
		"status": status,
		"progress": progress,
		"message": message,
		"metadata": metadata.duplicate(true),
	}
