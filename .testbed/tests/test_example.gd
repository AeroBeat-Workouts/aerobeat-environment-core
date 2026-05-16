extends GutTest

const README_PATH := "../README.md"
const PLUGIN_CFG_PATH := "../plugin.cfg"
const ADDONS_MANIFEST_PATH := "addons.jsonc"
const PROJECT_GODOT_PATH := "project.godot"
const EXPECTED_PLUGIN_NAME := "AeroBeat Environment Core"
const EXPECTED_PLUGIN_DESCRIPTION := "Shared environment contract/core package for AeroBeat. Owns environment request/result/progress/config vocabulary and helpers on top of aerobeat-asset-core."
const EXPECTED_TESTBED_NAME := "AeroBeat Internal Environment Testbed"

func _read_repo_file(relative_path: String) -> String:
	var absolute_path := ProjectSettings.globalize_path("res://%s" % relative_path)
	assert_true(FileAccess.file_exists(absolute_path), "Expected repo file to exist: %s" % absolute_path)
	var file := FileAccess.open(absolute_path, FileAccess.READ)
	assert_true(file != null, "Expected repo file to open: %s" % absolute_path)
	return file.get_as_text()

func test_readme_describes_environment_contract_core_boundary() -> void:
	var readme_text := _read_repo_file(README_PATH)
	assert_true(readme_text.contains("shared **environment-lane contract package**"), "README should describe the environment contract role")
	assert_true(readme_text.contains("not a new universal architecture lane"), "README should preserve the narrow lane boundary")
	assert_true(readme_text.contains("typed request/result/error/progress/config contracts"), "README should document the contract slice")
	assert_true(readme_text.contains("aerobeat-environment-loader"), "README should document downstream loader adoption intent")
	assert_true(readme_text.contains("aerobeat-environment-gaussian-splat"), "README should document downstream splat adoption intent")

func test_plugin_cfg_description_matches_environment_core_scope() -> void:
	var config := ConfigFile.new()
	var error := config.load(ProjectSettings.globalize_path("res://%s" % PLUGIN_CFG_PATH))
	assert_eq(error, OK, "plugin.cfg should parse cleanly")
	assert_eq(config.get_value("plugin", "name", ""), EXPECTED_PLUGIN_NAME, "plugin.cfg name should reflect the environment core role")
	assert_eq(
		config.get_value("plugin", "description", ""),
		EXPECTED_PLUGIN_DESCRIPTION,
		"plugin.cfg description should reflect the shared environment contract boundary"
	)

func test_addons_manifest_keeps_expected_dependencies_only() -> void:
	var manifest_text := _read_repo_file(ADDONS_MANIFEST_PATH)
	assert_true(manifest_text.contains('"aerobeat-asset-core"'), "addons manifest should pin aerobeat-asset-core")
	assert_true(manifest_text.contains('"gut"'), "addons manifest should pin gut for repo-local tests")
	assert_false(manifest_text.contains('"aerobeat-core"'), "addons manifest should not reintroduce stale aerobeat-core drift")

func test_hidden_testbed_name_stays_internal_template_specific() -> void:
	var config := ConfigFile.new()
	var error := config.load(ProjectSettings.globalize_path("res://%s" % PROJECT_GODOT_PATH))
	assert_eq(error, OK, "project.godot should parse cleanly")
	assert_eq(
		config.get_value("application", "config/name", ""),
		EXPECTED_TESTBED_NAME,
		"hidden workbench name should stay aligned with the internal environment testbed contract"
	)
