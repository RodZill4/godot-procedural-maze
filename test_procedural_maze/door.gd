tool
extends StaticBody

func set_color(color):
	var material = SpatialMaterial.new()
	material.albedo_color = color
	$Wall1.set_surface_material(0, material)
	$Wall2.set_surface_material(0, material)
	$Wall3.set_surface_material(0, material)
