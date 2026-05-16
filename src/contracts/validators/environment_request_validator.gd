class_name AeroEnvironmentRequestValidator
extends RefCounted

const AeroEnvironmentConstants = preload("../globals/aero_environment_constants.gd")
const AeroEnvironmentRequest = preload("../data_types/environment_request.gd")
const AeroEnvironmentError = preload("../data_types/environment_error.gd")

static func normalize_request_dict(request: Dictionary, auto_fill_config: bool = true) -> Dictionary:
	var normalized_request = AeroEnvironmentRequest.from_dict(request)
	if normalized_request.kind.is_empty():
		return _invalid_request(normalized_request, "Environment request is missing kind.")
	if not AeroEnvironmentConstants.supports_kind(normalized_request.kind):
		return _error_result(
			normalized_request,
			AeroEnvironmentConstants.ERROR_UNSUPPORTED_FORMAT,
			"Environment kind '%s' is not supported." % normalized_request.kind
		)
	if normalized_request.asset_path.is_empty():
		return _invalid_request(normalized_request, "Environment request is missing asset_path.")
	var detected_format := AeroEnvironmentConstants.detect_format(normalized_request.asset_path)
	var required_format := AeroEnvironmentConstants.required_format_for_kind(normalized_request.kind)
	if detected_format != required_format:
		return _error_result(
			normalized_request,
			AeroEnvironmentConstants.ERROR_UNSUPPORTED_FORMAT,
			"Environment kind '%s' requires %s assets, got %s." % [normalized_request.kind, required_format, detected_format]
		)
	if auto_fill_config and normalized_request.config_path.is_empty() and (
		normalized_request.kind == AeroEnvironmentConstants.KIND_GLB
		or normalized_request.kind == AeroEnvironmentConstants.KIND_SPLAT
	):
		var preferred_config_path := AeroEnvironmentConstants.preferred_config_path(normalized_request.asset_path)
		if path_exists(preferred_config_path):
			normalized_request.config_path = preferred_config_path
	return {
		"ok": true,
		"request": normalized_request,
		"request_dict": normalized_request.to_dict(),
	}

static func path_exists(path: String) -> bool:
	var absolute_path := to_absolute_path(path)
	return not absolute_path.is_empty() and FileAccess.file_exists(absolute_path)

static func to_absolute_path(path: String) -> String:
	var normalized := path.strip_edges()
	if normalized.is_empty():
		return ""
	if normalized.begins_with("res://") or normalized.begins_with("user://"):
		return ProjectSettings.globalize_path(normalized)
	return normalized.simplify_path() if normalized.is_absolute_path() else ProjectSettings.globalize_path(normalized)

static func to_resource_path(path: String) -> String:
	var normalized := path.strip_edges()
	if normalized.is_empty():
		return ""
	if normalized.begins_with("res://") or normalized.begins_with("user://"):
		return normalized
	if not normalized.is_absolute_path():
		return ProjectSettings.localize_path(ProjectSettings.globalize_path(normalized))
	var project_root := ProjectSettings.globalize_path("res://")
	if normalized.begins_with(project_root):
		return ProjectSettings.localize_path(normalized)
	return ""

static func _invalid_request(request, message: String) -> Dictionary:
	return _error_result(request, AeroEnvironmentConstants.ERROR_INVALID_REQUEST, message)

static func _error_result(request, error_code: String, message: String) -> Dictionary:
	var error := AeroEnvironmentError.new({
		"request_id": request.request_id,
		"kind": request.kind,
		"asset_path": request.asset_path,
		"error_code": error_code,
		"message": message,
		"recoverable": true,
		"metadata": request.metadata,
	})
	return {
		"ok": false,
		"request": request,
		"request_dict": request.to_dict(),
		"error": error,
		"error_dict": error.to_dict(),
		"error_code": error.error_code,
		"message": error.message,
		"recoverable": error.recoverable,
	}
