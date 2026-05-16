extends GutTest

const README_PATH := "../README.md"
const PLUGIN_CFG_PATH := "../plugin.cfg"
const ADDONS_MANIFEST_PATH := "addons.jsonc"
const PROJECT_GODOT_PATH := "project.godot"
const EXPECTED_PLUGIN_DESCRIPTION := "Template for AeroBeat internal environment repos. Shared environment resources built on aerobeat-asset-core for current v1 work."
const EXPECTED_TESTBED_NAME := "AeroBeat Internal Environment Testbed"

func _read_repo_file(relative_path: String) -> String:
	var absolute_path := ProjectSettings.globalize_path("res://%s" % relative_path)
	assert_true(FileAccess.file_exists(absolute_path), "Expected repo file to exist: %s" % absolute_path)
	var file := FileAccess.open(absolute_path, FileAccess.READ)
	assert_true(file != null, "Expected repo file to open: %s" % absolute_path)
	return file.get_as_text()

func test_readme_keeps_v1_internal_environment_template_truth() -> void:
	var readme_text := _read_repo_file(README_PATH)
	assert_true(readme_text.contains("official template for creating **internal environment** repositories"), "README should state that this repo is an internal environment template")
	assert_true(readme_text.contains("PC community first"), "README should preserve PC-first release wording")
	assert_true(readme_text.contains("Boxing and Flow"), "README should preserve the locked v1 feature slice")
	assert_true(readme_text.contains("camera only"), "README should preserve camera-only official gameplay input wording")
	assert_true(readme_text.contains("internal/system environment work"), "README should preserve the downscoped internal-only environment stance")
	assert_true(readme_text.contains("UGC or package-local gameplay environment swap story"), "README should explicitly reject the old UGC/package-local environment framing")

func test_plugin_cfg_description_stays_template_specific() -> void:
	var config := ConfigFile.new()
	var error := config.load(ProjectSettings.globalize_path("res://%s" % PLUGIN_CFG_PATH))
	assert_eq(error, OK, "plugin.cfg should parse cleanly")
	assert_eq(config.get_value("plugin", "name", ""), "AeroBeat Internal Environment Template", "plugin.cfg name should stay stable")
	assert_eq(
		config.get_value("plugin", "description", ""),
		EXPECTED_PLUGIN_DESCRIPTION,
		"plugin.cfg description should remain aligned with the template's narrow v1 environment-lane contract"
	)

func test_addons_manifest_keeps_expected_dependencies_only() -> void:
	var manifest_text := _read_repo_file(ADDONS_MANIFEST_PATH)
	assert_true(manifest_text.contains('"aerobeat-asset-core"'), "addons manifest should pin aerobeat-asset-core")
	assert_true(manifest_text.contains('"checkout": "main"'), "addons manifest should document the honest main-branch baseline for aerobeat-asset-core")
	assert_true(manifest_text.contains('"gut"'), "addons manifest should pin gut for repo-local tests")
	assert_false(manifest_text.contains('"aerobeat-core"'), "addons manifest should not reintroduce stale aerobeat-core drift")

func test_hidden_testbed_name_stays_internal_template_specific() -> void:
	var config := ConfigFile.new()
	var error := config.load(ProjectSettings.globalize_path("res://%s" % PROJECT_GODOT_PATH))
	assert_eq(error, OK, "project.godot should parse cleanly")
	assert_eq(
		config.get_value("application", "config/name", ""),
		EXPECTED_TESTBED_NAME,
		"hidden workbench name should stay aligned with the internal environment template contract"
	)
