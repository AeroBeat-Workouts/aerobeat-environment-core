class_name AeroEnvironmentFulfillment
extends RefCounted

func get_handler_name() -> String:
	return ""

func supports_kind(_kind: String) -> bool:
	return false

func fulfill(_request: Variant) -> Variant:
	push_error("AeroEnvironmentFulfillment.fulfill must be implemented by a concrete provider.")
	return null
