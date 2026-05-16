class_name AeroEnvironmentConstants
extends RefCounted

const KIND_IMAGE := "image"
const KIND_VIDEO := "video"
const KIND_GLB := "glb"
const KIND_SPLAT := "splat"

const DISPLAY_MODE_COVER := "cover"
const DISPLAY_MODE_CONTAIN := "contain"

const ERROR_FILE_MISSING := "file_missing"
const ERROR_UNSUPPORTED_FORMAT := "unsupported_format"
const ERROR_INVALID_REQUEST := "invalid_request"
const ERROR_INVALID_CONFIG := "invalid_config"
const ERROR_LOADER_FAILED := "loader_failed"

const STATE_PENDING := "pending"
const STATE_RUNNING := "running"
const STATE_SUCCEEDED := "succeeded"
const STATE_FAILED := "failed"
const STATE_CANCELLED := "cancelled"

const STATUS_QUEUED := "queued"
const STATUS_RESOLVING := "resolving"
const STATUS_LOADING := "loading"
const STATUS_DECODING := "decoding"
const STATUS_INSTANTIATING := "instantiating"
const STATUS_APPLYING_CONFIG := "applying_config"
const STATUS_READY := "ready"
const STATUS_FAILED := "failed"
const STATUS_CANCELLED := "cancelled"

const SUPPORTED_KINDS := [
	KIND_IMAGE,
	KIND_VIDEO,
	KIND_GLB,
	KIND_SPLAT,
]

const SUPPORTED_STATES := [
	STATE_PENDING,
	STATE_RUNNING,
	STATE_SUCCEEDED,
	STATE_FAILED,
	STATE_CANCELLED,
]

const TERMINAL_STATES := [
	STATE_SUCCEEDED,
	STATE_FAILED,
	STATE_CANCELLED,
]

const SUPPORTED_STATUSES := [
	STATUS_QUEUED,
	STATUS_RESOLVING,
	STATUS_LOADING,
	STATUS_DECODING,
	STATUS_INSTANTIATING,
	STATUS_APPLYING_CONFIG,
	STATUS_READY,
	STATUS_FAILED,
	STATUS_CANCELLED,
]

const OFFICIAL_FORMATS := {
	KIND_IMAGE: ".png",
	KIND_VIDEO: ".ogv",
	KIND_GLB: ".glb",
	KIND_SPLAT: ".compressed.ply",
}

static func normalize_kind(kind: String) -> String:
	return kind.strip_edges().to_lower()

static func normalize_display_mode(display_mode: String) -> String:
	return DISPLAY_MODE_CONTAIN if display_mode.strip_edges().to_lower() == DISPLAY_MODE_CONTAIN else DISPLAY_MODE_COVER

static func normalize_state(state: String) -> String:
	return state.strip_edges().to_lower()

static func supports_kind(kind: String) -> bool:
	return SUPPORTED_KINDS.has(normalize_kind(kind))

static func supports_state(state: String) -> bool:
	return SUPPORTED_STATES.has(normalize_state(state))

static func is_terminal_state(state: String) -> bool:
	return TERMINAL_STATES.has(normalize_state(state))

static func supports_status(status: String) -> bool:
	return SUPPORTED_STATUSES.has(status.strip_edges().to_lower())

static func required_format_for_kind(kind: String) -> String:
	return String(OFFICIAL_FORMATS.get(normalize_kind(kind), ""))

static func detect_format(asset_path: String) -> String:
	var lower := asset_path.strip_edges().to_lower()
	for format in OFFICIAL_FORMATS.values():
		if lower.ends_with(String(format)):
			return String(format)
	var extension := lower.get_extension()
	return ".%s" % extension if not extension.is_empty() else ""

static func preferred_config_path(asset_path: String) -> String:
	var normalized := asset_path.strip_edges()
	if normalized.is_empty():
		return ""
	var lower := normalized.to_lower()
	if lower.ends_with(OFFICIAL_FORMATS[KIND_SPLAT]):
		return normalized.substr(0, normalized.length() - OFFICIAL_FORMATS[KIND_SPLAT].length()) + ".json"
	if lower.ends_with(OFFICIAL_FORMATS[KIND_GLB]):
		return normalized.substr(0, normalized.length() - OFFICIAL_FORMATS[KIND_GLB].length()) + ".json"
	return normalized + ".json"
