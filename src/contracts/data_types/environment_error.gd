class_name AeroEnvironmentError
extends RefCounted

const AeroEnvironmentConstants = preload("../globals/aero_environment_constants.gd")

var ok: bool = false
var request_id: String = ""
var kind: String = ""
var asset_path: String = ""
var error_code: String = AeroEnvironmentConstants.ERROR_INVALID_REQUEST
var message: String = ""
var recoverable: bool = true
var metadata: Dictionary = {}
var details: Dictionary = {}

func _init(data: Dictionary = {}) -> void:
	apply_dict(data)

static func from_dict(data: Dictionary):
	return new(data)

func apply_dict(data: Dictionary):
	ok = bool(data.get("ok", false))
	request_id = String(data.get("request_id", "")).strip_edges()
	kind = AeroEnvironmentConstants.normalize_kind(String(data.get("kind", "")))
	asset_path = String(data.get("asset_path", "")).strip_edges()
	error_code = String(data.get("error_code", AeroEnvironmentConstants.ERROR_INVALID_REQUEST)).strip_edges().to_lower()
	message = String(data.get("message", "")).strip_edges()
	recoverable = bool(data.get("recoverable", true))
	metadata = Dictionary(data.get("metadata", {})) if data.get("metadata", {}) is Dictionary else {}
	details = Dictionary(data.get("details", {})) if data.get("details", {}) is Dictionary else {}
	return self

func to_dict() -> Dictionary:
	return {
		"ok": ok,
		"request_id": request_id,
		"kind": kind,
		"asset_path": asset_path,
		"error_code": error_code,
		"message": message,
		"recoverable": recoverable,
		"metadata": metadata.duplicate(true),
		"details": details.duplicate(true),
	}
