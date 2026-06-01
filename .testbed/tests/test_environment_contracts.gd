extends GutTest

const CONSTANTS_SCRIPT := "../src/contracts/globals/aero_environment_constants.gd"
const REQUEST_SCRIPT := "../src/contracts/data_types/environment_request.gd"
const RESULT_SCRIPT := "../src/contracts/data_types/environment_result.gd"
const ERROR_SCRIPT := "../src/contracts/data_types/environment_error.gd"
const PROGRESS_SCRIPT := "../src/contracts/data_types/environment_progress.gd"
const OPERATION_SCRIPT := "../src/contracts/data_types/environment_operation.gd"
const CONFIG_SCRIPT := "../src/contracts/data_types/environment_config.gd"
const TRANSFORM_CONFIG_SCRIPT := "../src/contracts/data_types/environment_transform_config.gd"
const MEDIA_CONFIG_SCRIPT := "../src/contracts/data_types/environment_media_config.gd"
const FULFILLMENT_SCRIPT := "../src/contracts/interfaces/environment_fulfillment.gd"
const KIND_HANDLER_SCRIPT := "../src/contracts/interfaces/environment_kind_handler.gd"
const REQUEST_VALIDATOR_SCRIPT := "../src/contracts/validators/environment_request_validator.gd"
const CONFIG_HELPER_SCRIPT := "../src/contracts/validators/environment_config_helper.gd"
const FAKE_SUCCESS_FULFILLMENT_SCRIPT := "res://tests/support/fake_success_fulfillment.gd"
const FAKE_FAILURE_FULFILLMENT_SCRIPT := "res://tests/support/fake_failure_fulfillment.gd"

func _load_repo_script(relative_path: String) -> Script:
	var absolute_path := ProjectSettings.globalize_path("res://%s" % relative_path)
	assert_true(FileAccess.file_exists(absolute_path), "Expected repo script to exist: %s" % absolute_path)
	var script := load(absolute_path)
	assert_true(script != null, "Expected repo script to load: %s" % absolute_path)
	return script

func test_contract_scripts_exist_and_load() -> void:
	for relative_path in [
		CONSTANTS_SCRIPT,
		REQUEST_SCRIPT,
		RESULT_SCRIPT,
		ERROR_SCRIPT,
		PROGRESS_SCRIPT,
		OPERATION_SCRIPT,
		CONFIG_SCRIPT,
		TRANSFORM_CONFIG_SCRIPT,
		MEDIA_CONFIG_SCRIPT,
		FULFILLMENT_SCRIPT,
		KIND_HANDLER_SCRIPT,
		REQUEST_VALIDATOR_SCRIPT,
		CONFIG_HELPER_SCRIPT,
	]:
		assert_true(_load_repo_script(relative_path) != null, "Expected script to load: %s" % relative_path)

func test_request_validator_normalizes_environment_request_shape() -> void:
	var validator_script := _load_repo_script(REQUEST_VALIDATOR_SCRIPT)
	var temp_dir := ProjectSettings.globalize_path("user://environment_contract_tests")
	DirAccess.make_dir_recursive_absolute(temp_dir)
	var asset_path := "%s/sample_scene.glb" % temp_dir
	var config_path := "%s/sample_scene.config.yaml" % temp_dir
	FileAccess.open(asset_path, FileAccess.WRITE).store_string("fake glb placeholder")
	FileAccess.open(config_path, FileAccess.WRITE).store_string("transform:\n  position: [0, 0, 0]\n")

	var result: Dictionary = validator_script.normalize_request_dict({
		"request_id": "  req-42  ",
		"kind": " GLB ",
		"asset_path": asset_path,
		"fit_mode": "contain",
		"context": {"source": "test"},
		"metadata": {"tag": "contract"},
	})

	assert_true(result.get("ok", false), "Expected request normalization to succeed")
	var request = result.get("request")
	assert_eq(request.request_id, "req-42")
	assert_eq(request.kind, "glb")
	assert_eq(request.fit_mode, "contain")
	assert_eq(request.config_path, config_path)
	assert_eq(result.get("request_dict", {}).get("configPath", ""), config_path)
	assert_eq(result.get("request_dict", {}).get("metadata", {}).get("tag", ""), "contract")

func test_request_validator_accepts_configpath_alias_and_media_kinds() -> void:
	var validator_script := _load_repo_script(REQUEST_VALIDATOR_SCRIPT)
	var temp_dir := ProjectSettings.globalize_path("user://environment_contract_tests_media")
	DirAccess.make_dir_recursive_absolute(temp_dir)
	var asset_path := "%s/hero.png" % temp_dir
	var config_path := "%s/hero.config.yaml" % temp_dir
	FileAccess.open(asset_path, FileAccess.WRITE).store_string("fake image placeholder")
	FileAccess.open(config_path, FileAccess.WRITE).store_string("media:\n  fit_mode: stretch\n")

	var result: Dictionary = validator_script.normalize_request_dict({
		"request_id": "req-media",
		"kind": "image",
		"asset_path": asset_path,
		"configPath": "  %s  " % config_path,
		"display_mode": "stretch",
	})

	assert_true(result.get("ok", false), "Expected media request normalization to succeed")
	var request = result.get("request")
	assert_eq(request.config_path, config_path)
	assert_eq(request.fit_mode, "stretch")
	assert_eq(result.get("request_dict", {}).get("display_mode", ""), "stretch")

func test_constants_preferred_config_path_uses_yaml_sidecars() -> void:
	var constants_script := _load_repo_script(CONSTANTS_SCRIPT)
	assert_eq(constants_script.preferred_config_path("res://assets/environments/sky.glb"), "res://assets/environments/sky.config.yaml")
	assert_eq(constants_script.preferred_config_path("res://assets/environments/clouds.compressed.ply"), "res://assets/environments/clouds.config.yaml")
	assert_eq(constants_script.preferred_config_path("res://assets/environments/poster.png"), "res://assets/environments/poster.config.yaml")
	assert_eq(constants_script.normalize_fit_mode(" STRETCH "), "stretch")
	assert_eq(constants_script.normalize_fit_mode("unknown"), "cover")

func test_config_helper_applies_nested_transform_and_defaults_media_fit_mode() -> void:
	var helper_script := _load_repo_script(CONFIG_HELPER_SCRIPT)
	var target := Node3D.new()
	var result: Dictionary = helper_script.apply_config_dict({
		"transform": {
			"position": [1, 2, 3],
			"rotation_degrees": {"x": 10, "y": 20, "z": 30},
			"scale": [2, 3, 4],
		},
		"media": {},
	}, target)

	assert_true(result.get("ok", false), "Expected config helper to apply successfully")
	assert_eq(target.position, Vector3(1, 2, 3))
	assert_almost_eq(target.rotation_degrees.x, 10.0, 0.001)
	assert_almost_eq(target.rotation_degrees.y, 20.0, 0.001)
	assert_almost_eq(target.rotation_degrees.z, 30.0, 0.001)
	assert_eq(target.scale, Vector3(2, 3, 4))
	assert_eq(result.get("config").media.fit_mode, "cover")
	target.free()

func test_config_data_type_round_trips_nested_transform_and_media() -> void:
	var config_script := _load_repo_script(CONFIG_SCRIPT)
	var config = config_script.new({
		"transform": {
			"position": [4, 5, 6],
		},
		"media": {
			"fit_mode": "contain",
		},
		"tag": "demo",
	})
	assert_eq(config.transform.position, Vector3(4, 5, 6))
	assert_eq(config.transform.rotation_degrees, Vector3.ZERO)
	assert_eq(config.transform.scale, Vector3.ONE)
	assert_eq(config.media.fit_mode, "contain")
	assert_eq(config.extras.get("tag", ""), "demo")
	assert_eq(config.to_dict().get("transform", {}).get("scale", []), [1.0, 1.0, 1.0])
	assert_eq(config.to_dict().get("media", {}).get("fit_mode", ""), "contain")

func test_data_type_round_trip_and_kind_handler_behavior() -> void:
	var request_script := _load_repo_script(REQUEST_SCRIPT)
	var result_script := _load_repo_script(RESULT_SCRIPT)
	var error_script := _load_repo_script(ERROR_SCRIPT)
	var progress_script := _load_repo_script(PROGRESS_SCRIPT)
	var kind_handler_script := _load_repo_script(KIND_HANDLER_SCRIPT)

	var request = request_script.new({
		"request_id": "req-round-trip",
		"kind": "splat",
		"asset_path": "/tmp/sample.compressed.ply",
		"configPath": "/tmp/sample.config.yaml",
		"fit_mode": "stretch",
		"metadata": {"a": 1},
	})
	assert_eq(request.to_dict().get("kind", ""), "splat")
	assert_eq(request.to_dict().get("config_path", ""), "/tmp/sample.config.yaml")
	assert_eq(request.to_dict().get("configPath", ""), "/tmp/sample.config.yaml")
	assert_eq(request.to_dict().get("fit_mode", ""), "stretch")

	var result = result_script.new({
		"request_id": request.request_id,
		"kind": request.kind,
		"asset_path": request.asset_path,
		"configPath": request.config_path,
		"format": ".compressed.ply",
		"details": {"point_count": 12},
	})
	assert_eq(result.to_dict().get("details", {}).get("point_count", 0), 12)
	assert_eq(result.to_dict().get("configPath", ""), request.config_path)

	var error = error_script.new({
		"request_id": request.request_id,
		"kind": request.kind,
		"asset_path": request.asset_path,
		"error_code": "loader_failed",
		"message": "boom",
	})
	assert_eq(error.to_dict().get("message", ""), "boom")

	var progress = progress_script.new({
		"request_id": request.request_id,
		"kind": request.kind,
		"asset_path": request.asset_path,
		"state": " RUNNING ",
		"status": "ready",
		"phase": " Building ",
		"progress": 4.0,
		"sequence": -3,
		"indeterminate": true,
	})
	assert_eq(progress.state, "running")
	assert_eq(progress.phase, "building")
	assert_eq(progress.progress, 1.0)
	assert_eq(progress.sequence, 0)
	assert_true(progress.indeterminate)

	var handler = kind_handler_script.new("splat")
	assert_true(handler.supports_kind(" SPLAT "), "Kind handler should normalize kind lookups")
	assert_false(handler.supports_kind("glb"), "Kind handler should reject other kinds")

func test_operation_lifecycle_emits_typed_signals_and_tracks_terminal_state() -> void:
	var request_script := _load_repo_script(REQUEST_SCRIPT)
	var operation_script := _load_repo_script(OPERATION_SCRIPT)
	var request = request_script.new({
		"request_id": "req-op-success",
		"kind": "splat",
		"asset_path": "/tmp/hero.compressed.ply",
		"configPath": "/tmp/hero.config.yaml",
		"fit_mode": "contain",
	})
	var operation = operation_script.new(request)
	var events: Array[String] = []
	var sequences: Array[int] = []

	operation.started.connect(func(progress):
		events.append("started")
		sequences.append(progress.sequence)
	)
	operation.progressed.connect(func(progress):
		events.append("progressed")
		sequences.append(progress.sequence)
	)
	operation.succeeded.connect(func(_result):
		events.append("succeeded")
	)
	operation.finished.connect(func(finished_operation):
		events.append("finished")
		assert_true(finished_operation.is_terminal())
	)

	var started = operation.mark_started({
		"status": "loading",
		"phase": "reading",
		"indeterminate": true,
	})
	var progressed = operation.push_progress({
		"status": "decoding",
		"phase": "building",
		"progress": 0.5,
	})
	var result = operation.succeed({
		"request_id": request.request_id,
		"kind": request.kind,
		"asset_path": request.asset_path,
		"configPath": request.config_path,
		"format": ".compressed.ply",
	})

	assert_eq(started.state, "running")
	assert_eq(progressed.status, "decoding")
	assert_eq(operation.state, "succeeded")
	assert_eq(operation.latest_progress.state, "succeeded")
	assert_eq(operation.latest_progress.status, "ready")
	assert_eq(operation.latest_progress.progress, 1.0)
	assert_eq(result.format, ".compressed.ply")
	assert_eq(result.config_path, request.config_path)
	assert_eq(events, ["started", "progressed", "succeeded", "finished"])
	assert_eq(sequences, [1, 2])

func test_operation_cancel_and_failure_paths_are_typed() -> void:
	var request_script := _load_repo_script(REQUEST_SCRIPT)
	var operation_script := _load_repo_script(OPERATION_SCRIPT)
	var request = request_script.new({
		"request_id": "req-op-fail",
		"kind": "glb",
		"asset_path": "/tmp/fail.glb",
	})
	var failed_events: Array[String] = []
	var failed_operation = operation_script.new(request)
	failed_operation.failed.connect(func(error):
		failed_events.append(error.error_code)
	)
	failed_operation.finished.connect(func(_operation):
		failed_events.append("finished")
	)

	failed_operation.mark_started({"status": "loading"})
	var error = failed_operation.fail({
		"request_id": request.request_id,
		"kind": request.kind,
		"asset_path": request.asset_path,
		"error_code": "loader_failed",
		"message": "nope",
	})
	assert_eq(error.error_code, "loader_failed")
	assert_eq(failed_operation.latest_progress.state, "failed")
	assert_eq(failed_operation.latest_progress.status, "failed")
	assert_eq(failed_events, ["loader_failed", "finished"])

	var cancelled_operation = operation_script.new(request)
	cancelled_operation.mark_started({"status": "loading"})
	var cancelled_progress = cancelled_operation.cancel("user cancelled")
	assert_eq(cancelled_operation.state, "cancelled")
	assert_eq(cancelled_progress.status, "cancelled")
	assert_eq(cancelled_progress.message, "user cancelled")
	assert_true(cancelled_operation.is_terminal())

func test_begin_fulfill_wraps_sync_success_into_finished_operation() -> void:
	var request_script := _load_repo_script(REQUEST_SCRIPT)
	var request = request_script.new({
		"request_id": "req-sync-success",
		"kind": "splat",
		"asset_path": "/tmp/success.compressed.ply",
		"configPath": "/tmp/success.config.yaml",
	})
	var fulfillment = load(FAKE_SUCCESS_FULFILLMENT_SCRIPT).new()
	var operation = fulfillment.begin_fulfill(request)

	assert_false(fulfillment.supports_async())
	assert_true(operation.is_terminal())
	assert_eq(operation.state, "succeeded")
	assert_eq(operation.latest_progress.state, "succeeded")
	assert_eq(operation.latest_progress.status, "ready")
	assert_eq(operation.result.details.get("wrapped", false), true)
	assert_eq(operation.result.config_path, request.config_path)
	assert_eq(operation.error, null)

func test_begin_fulfill_wraps_sync_failure_into_finished_operation() -> void:
	var request_script := _load_repo_script(REQUEST_SCRIPT)
	var request = request_script.new({
		"request_id": "req-sync-fail",
		"kind": "glb",
		"asset_path": "/tmp/fail.glb",
	})
	var fulfillment = load(FAKE_FAILURE_FULFILLMENT_SCRIPT).new()
	var operation = fulfillment.begin_fulfill(request)

	assert_true(operation.is_terminal())
	assert_eq(operation.state, "failed")
	assert_eq(operation.latest_progress.state, "failed")
	assert_eq(operation.latest_progress.status, "failed")
	assert_eq(operation.error.message, "sync boom")
	assert_eq(operation.result, null)
