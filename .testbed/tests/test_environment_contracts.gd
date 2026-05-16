extends GutTest

const CONSTANTS_SCRIPT := "../src/contracts/globals/aero_environment_constants.gd"
const REQUEST_SCRIPT := "../src/contracts/data_types/environment_request.gd"
const RESULT_SCRIPT := "../src/contracts/data_types/environment_result.gd"
const ERROR_SCRIPT := "../src/contracts/data_types/environment_error.gd"
const PROGRESS_SCRIPT := "../src/contracts/data_types/environment_progress.gd"
const CONFIG_SCRIPT := "../src/contracts/data_types/environment_config.gd"
const FULFILLMENT_SCRIPT := "../src/contracts/interfaces/environment_fulfillment.gd"
const KIND_HANDLER_SCRIPT := "../src/contracts/interfaces/environment_kind_handler.gd"
const REQUEST_VALIDATOR_SCRIPT := "../src/contracts/validators/environment_request_validator.gd"
const CONFIG_HELPER_SCRIPT := "../src/contracts/validators/environment_config_helper.gd"

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
		CONFIG_SCRIPT,
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
	var config_path := "%s/sample_scene.json" % temp_dir
	FileAccess.open(asset_path, FileAccess.WRITE).store_string("fake glb placeholder")
	FileAccess.open(config_path, FileAccess.WRITE).store_string("{}")

	var result: Dictionary = validator_script.normalize_request_dict({
		"request_id": "  req-42  ",
		"kind": " GLB ",
		"asset_path": asset_path,
		"display_mode": "contain",
		"context": {"source": "test"},
		"metadata": {"tag": "contract"},
	})

	assert_true(result.get("ok", false), "Expected request normalization to succeed")
	var request = result.get("request")
	assert_eq(request.request_id, "req-42")
	assert_eq(request.kind, "glb")
	assert_eq(request.display_mode, "contain")
	assert_eq(request.config_path, config_path)
	assert_eq(result.get("request_dict", {}).get("metadata", {}).get("tag", ""), "contract")

func test_request_validator_reports_unsupported_format_with_typed_error() -> void:
	var validator_script := _load_repo_script(REQUEST_VALIDATOR_SCRIPT)
	var result: Dictionary = validator_script.normalize_request_dict({
		"request_id": "req-bad",
		"kind": "image",
		"asset_path": "/tmp/not-an-image.glb",
	})

	assert_false(result.get("ok", true), "Expected invalid format to fail")
	assert_eq(result.get("error_code", ""), "unsupported_format")
	assert_true(result.has("error"), "Expected typed error contract to be returned")
	assert_eq(result.get("error_dict", {}).get("request_id", ""), "req-bad")

func test_config_helper_applies_transform_to_node3d() -> void:
	var helper_script := _load_repo_script(CONFIG_HELPER_SCRIPT)
	var target := Node3D.new()
	var result: Dictionary = helper_script.apply_config_dict({
		"position": [1, 2, 3],
		"rotation_degrees": {"x": 10, "y": 20, "z": 30},
		"scale": [2, 3, 4],
	}, target)

	assert_true(result.get("ok", false), "Expected config helper to apply successfully")
	assert_eq(target.position, Vector3(1, 2, 3))
	assert_almost_eq(target.rotation_degrees.x, 10.0, 0.001)
	assert_almost_eq(target.rotation_degrees.y, 20.0, 0.001)
	assert_almost_eq(target.rotation_degrees.z, 30.0, 0.001)
	assert_eq(target.scale, Vector3(2, 3, 4))
	target.queue_free()

func test_data_type_round_trip_and_kind_handler_behavior() -> void:
	var request_script := _load_repo_script(REQUEST_SCRIPT)
	var result_script := _load_repo_script(RESULT_SCRIPT)
	var error_script := _load_repo_script(ERROR_SCRIPT)
	var progress_script := _load_repo_script(PROGRESS_SCRIPT)
	var config_script := _load_repo_script(CONFIG_SCRIPT)
	var kind_handler_script := _load_repo_script(KIND_HANDLER_SCRIPT)

	var request = request_script.new({
		"request_id": "req-round-trip",
		"kind": "splat",
		"asset_path": "/tmp/sample.compressed.ply",
		"metadata": {"a": 1},
	})
	assert_eq(request.to_dict().get("kind", ""), "splat")

	var result = result_script.new({
		"request_id": request.request_id,
		"kind": request.kind,
		"asset_path": request.asset_path,
		"format": ".compressed.ply",
		"details": {"point_count": 12},
	})
	assert_eq(result.to_dict().get("details", {}).get("point_count", 0), 12)

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
		"status": "ready",
		"progress": 4.0,
	})
	assert_eq(progress.progress, 1.0)

	var config = config_script.new({
		"position": [4, 5, 6],
	})
	assert_eq(config.position, Vector3(4, 5, 6))

	var handler = kind_handler_script.new("splat")
	assert_true(handler.supports_kind(" SPLAT "), "Kind handler should normalize kind lookups")
	assert_false(handler.supports_kind("glb"), "Kind handler should reject other kinds")
