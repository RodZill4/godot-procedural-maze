tool
extends Spatial

func set_color(color):
	var material = SpatialMaterial.new()
	material.albedo_color = color
	$Spatial/MeshInstance.set_surface_material(0, material)
