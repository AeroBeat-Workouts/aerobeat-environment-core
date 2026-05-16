extends "../../../src/contracts/interfaces/environment_fulfillment.gd"

func fulfill(request: Variant) -> Variant:
	var request_dict: Dictionary = request.to_dict() if request != null and request.has_method("to_dict") else {}
	return {
		"request_id": request_dict.get("request_id", ""),
		"kind": request_dict.get("kind", ""),
		"asset_path": request_dict.get("asset_path", ""),
		"config_path": request_dict.get("config_path", ""),
		"format": ".compressed.ply",
		"details": {"wrapped": true},
	}
