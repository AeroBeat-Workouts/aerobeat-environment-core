class_name AeroEnvironmentFulfillment
extends RefCounted

const AeroEnvironmentConstants = preload("../globals/aero_environment_constants.gd")
const AeroEnvironmentRequest = preload("../data_types/environment_request.gd")
const AeroEnvironmentResult = preload("../data_types/environment_result.gd")
const AeroEnvironmentError = preload("../data_types/environment_error.gd")
const AeroEnvironmentOperation = preload("../data_types/environment_operation.gd")

func get_handler_name() -> String:
	return ""

func supports_kind(_kind: String) -> bool:
	return false

func supports_async() -> bool:
	return false

func fulfill(_request: Variant) -> Variant:
	push_error("AeroEnvironmentFulfillment.fulfill must be implemented by a concrete provider.")
	return null

func begin_fulfill(request: Variant) -> AeroEnvironmentOperation:
	var operation: AeroEnvironmentOperation = AeroEnvironmentOperation.new(request)
	var outcome: Variant = fulfill(request)
	if outcome is AeroEnvironmentError:
		operation.fail(outcome)
		return operation
	if outcome is AeroEnvironmentResult:
		operation.succeed(outcome)
		return operation
	if outcome is Dictionary and outcome.has("ok") and not bool(outcome.get("ok", true)):
		operation.fail(AeroEnvironmentError.new(outcome))
		return operation
	if outcome is Dictionary:
		operation.succeed(AeroEnvironmentResult.new(outcome))
		return operation
	if outcome == null:
		var fallback_request: AeroEnvironmentRequest = _coerce_request(request)
		operation.fail(AeroEnvironmentError.new({
			"request_id": fallback_request.request_id if fallback_request != null else "",
			"kind": fallback_request.kind if fallback_request != null else "",
			"asset_path": fallback_request.asset_path if fallback_request != null else "",
			"error_code": AeroEnvironmentConstants.ERROR_LOADER_FAILED,
			"message": "Fulfillment returned null.",
			"recoverable": false,
		}))
		return operation
	operation.succeed(AeroEnvironmentResult.new(_request_result_dict(request)))
	return operation

func _coerce_request(value: Variant) -> AeroEnvironmentRequest:
	if value is AeroEnvironmentRequest:
		return value
	if value is Dictionary:
		return AeroEnvironmentRequest.new(value)
	return null

func _request_result_dict(value: Variant) -> Dictionary:
	var request: AeroEnvironmentRequest = _coerce_request(value)
	if request == null:
		return {}
	return {
		"request_id": request.request_id,
		"kind": request.kind,
		"asset_path": request.asset_path,
		"config_path": request.config_path,
		"configPath": request.config_path,
		"fit_mode": request.fit_mode,
		"metadata": request.metadata.duplicate(true),
	}
