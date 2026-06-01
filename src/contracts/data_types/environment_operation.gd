class_name AeroEnvironmentOperation
extends RefCounted

const AeroEnvironmentConstants = preload("../globals/aero_environment_constants.gd")
const AeroEnvironmentRequest = preload("environment_request.gd")
const AeroEnvironmentResult = preload("environment_result.gd")
const AeroEnvironmentError = preload("environment_error.gd")
const AeroEnvironmentProgress = preload("environment_progress.gd")

signal started(progress: AeroEnvironmentProgress)
signal progressed(progress: AeroEnvironmentProgress)
signal succeeded(result: AeroEnvironmentResult)
signal failed(error: AeroEnvironmentError)
signal finished(operation: AeroEnvironmentOperation)

var request: AeroEnvironmentRequest = null
var latest_progress: AeroEnvironmentProgress = null
var result: AeroEnvironmentResult = null
var error: AeroEnvironmentError = null
var state: String = AeroEnvironmentConstants.STATE_PENDING
var _sequence_counter: int = 0

func _init(request_data: Variant = null) -> void:
	request = _coerce_request(request_data)
	if request != null:
		latest_progress = AeroEnvironmentProgress.new({
			"request_id": request.request_id,
			"kind": request.kind,
			"asset_path": request.asset_path,
			"state": AeroEnvironmentConstants.STATE_PENDING,
			"status": AeroEnvironmentConstants.STATUS_QUEUED,
			"progress": 0.0,
			"sequence": 0,
			"indeterminate": true,
		})

func is_terminal() -> bool:
	return AeroEnvironmentConstants.is_terminal_state(state)

func mark_started(progress_data: Variant = null) -> AeroEnvironmentProgress:
	var progress := _coerce_progress(progress_data)
	if progress == null:
		progress = _progress_from_request({})
	if progress.state.is_empty() or progress.state == AeroEnvironmentConstants.STATE_PENDING:
		progress.state = AeroEnvironmentConstants.STATE_RUNNING
	if progress.status.is_empty() or progress.status == AeroEnvironmentConstants.STATUS_QUEUED:
		progress.status = AeroEnvironmentConstants.STATUS_LOADING
	progress = _store_progress(progress)
	started.emit(progress)
	return progress

func push_progress(progress_data: Variant = null) -> AeroEnvironmentProgress:
	var progress := _coerce_progress(progress_data)
	if progress == null:
		progress = _progress_from_request({})
	if progress.state.is_empty() or progress.state == AeroEnvironmentConstants.STATE_PENDING:
		progress.state = AeroEnvironmentConstants.STATE_RUNNING
	progress = _store_progress(progress)
	progressed.emit(progress)
	return progress

func succeed(result_data: Variant, final_progress_data: Variant = null) -> AeroEnvironmentResult:
	result = _coerce_result(result_data)
	error = null
	state = AeroEnvironmentConstants.STATE_SUCCEEDED
	var progress := _coerce_progress(final_progress_data)
	if progress == null:
		progress = _progress_from_result(result)
	progress.state = AeroEnvironmentConstants.STATE_SUCCEEDED
	if progress.status.is_empty():
		progress.status = AeroEnvironmentConstants.STATUS_READY
	if progress.phase.is_empty():
		progress.phase = progress.status
		
	if progress.progress < 1.0 and not progress.indeterminate:
		progress.progress = 1.0
	_store_progress(progress)
	succeeded.emit(result)
	finished.emit(self)
	return result

func fail(error_data: Variant, final_progress_data: Variant = null) -> AeroEnvironmentError:
	error = _coerce_error(error_data)
	result = null
	state = AeroEnvironmentConstants.STATE_FAILED
	var progress := _coerce_progress(final_progress_data)
	if progress == null:
		progress = _progress_from_error(error)
	progress.state = AeroEnvironmentConstants.STATE_FAILED
	if progress.status.is_empty():
		progress.status = AeroEnvironmentConstants.STATUS_FAILED
	if progress.phase.is_empty():
		progress.phase = progress.status
	_store_progress(progress)
	failed.emit(error)
	finished.emit(self)
	return error

func cancel(message: String = "", final_progress_data: Variant = null) -> AeroEnvironmentProgress:
	result = null
	error = null
	state = AeroEnvironmentConstants.STATE_CANCELLED
	var progress := _coerce_progress(final_progress_data)
	if progress == null:
		progress = _progress_from_request({
			"message": message,
		})
	progress.state = AeroEnvironmentConstants.STATE_CANCELLED
	progress.status = AeroEnvironmentConstants.STATUS_CANCELLED
	if progress.phase.is_empty():
		progress.phase = AeroEnvironmentConstants.STATUS_CANCELLED
	if not message.is_empty() and progress.message.is_empty():
		progress.message = message
	progress.indeterminate = false
	_store_progress(progress)
	finished.emit(self)
	return progress

func to_dict() -> Dictionary:
	return {
		"request": request.to_dict() if request != null else {},
		"state": state,
		"latest_progress": latest_progress.to_dict() if latest_progress != null else {},
		"result": result.to_dict() if result != null else {},
		"error": error.to_dict() if error != null else {},
		"terminal": is_terminal(),
	}

func _store_progress(progress: AeroEnvironmentProgress) -> AeroEnvironmentProgress:
	_sequence_counter += 1
	progress.sequence = max(progress.sequence, _sequence_counter)
	state = progress.state if not progress.state.is_empty() else state
	latest_progress = progress
	return progress

func _coerce_request(value: Variant) -> AeroEnvironmentRequest:
	if value is AeroEnvironmentRequest:
		return value
	if value is Dictionary:
		return AeroEnvironmentRequest.new(value)
	return null

func _coerce_progress(value: Variant) -> AeroEnvironmentProgress:
	if value is AeroEnvironmentProgress:
		return value
	if value is Dictionary:
		return AeroEnvironmentProgress.new(_merge_request_fields(value))
	return null

func _coerce_result(value: Variant) -> AeroEnvironmentResult:
	if value is AeroEnvironmentResult:
		return value
	if value is Dictionary:
		return AeroEnvironmentResult.new(_merge_request_fields(value))
	return AeroEnvironmentResult.new(_request_base_dict())

func _coerce_error(value: Variant) -> AeroEnvironmentError:
	if value is AeroEnvironmentError:
		return value
	if value is Dictionary:
		return AeroEnvironmentError.new(_merge_request_fields(value))
	return AeroEnvironmentError.new(_request_base_dict())

func _request_base_dict() -> Dictionary:
	if request == null:
		return {}
	return {
		"request_id": request.request_id,
		"kind": request.kind,
		"asset_path": request.asset_path,
		"config_path": request.config_path,
		"configPath": request.config_path,
		"fit_mode": request.fit_mode,
		"display_mode": request.fit_mode,
		"metadata": request.metadata.duplicate(true),
	}

func _merge_request_fields(data: Dictionary) -> Dictionary:
	var merged := _request_base_dict()
	for key in data.keys():
		merged[key] = data[key]
	return merged

func _progress_from_request(data: Dictionary) -> AeroEnvironmentProgress:
	var payload := _merge_request_fields(data)
	if not payload.has("state"):
		payload["state"] = state
	if not payload.has("status"):
		payload["status"] = AeroEnvironmentConstants.STATUS_QUEUED
	return AeroEnvironmentProgress.new(payload)

func _progress_from_result(value: AeroEnvironmentResult) -> AeroEnvironmentProgress:
	return AeroEnvironmentProgress.new(_merge_request_fields({
		"request_id": value.request_id,
		"kind": value.kind,
		"asset_path": value.asset_path,
		"state": AeroEnvironmentConstants.STATE_SUCCEEDED,
		"status": AeroEnvironmentConstants.STATUS_READY,
		"phase": AeroEnvironmentConstants.STATUS_READY,
		"progress": 1.0,
		"indeterminate": false,
	}))

func _progress_from_error(value: AeroEnvironmentError) -> AeroEnvironmentProgress:
	return AeroEnvironmentProgress.new(_merge_request_fields({
		"request_id": value.request_id,
		"kind": value.kind,
		"asset_path": value.asset_path,
		"state": AeroEnvironmentConstants.STATE_FAILED,
		"status": AeroEnvironmentConstants.STATUS_FAILED,
		"phase": latest_progress.phase if latest_progress != null else AeroEnvironmentConstants.STATUS_FAILED,
		"progress": latest_progress.progress if latest_progress != null else 0.0,
		"message": value.message,
		"indeterminate": false,
	}))
