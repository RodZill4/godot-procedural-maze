tool
extends Area

func set_color(color):
	var material = SpatialMaterial.new()
	material.albedo_color = color
	$Spatial/MeshInstance.set_surface_material(0, material)

func _on_Key_body_entered(body):
	if body.has_method("get_key"):
		body.get_key($Spatial/MeshInstance.get_surface_material(0).albedo_color)
		queue_free()
