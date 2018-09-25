tool
extends StaticBody

var open = false

func set_color(color):
	var material = SpatialMaterial.new()
	material.albedo_color = color
	$Wall1.set_surface_material(0, material)
	$Wall2/Mesh.set_surface_material(0, material)
	$Wall3/Mesh.set_surface_material(0, material)
	$Door/Mesh.set_surface_material(0, material)


func _on_Area_body_entered(body):
	if !open and body.has_method("has_key") and body.has_key($Wall1.get_surface_material(0).albedo_color):
		$AnimationPlayer.play("open")
		open = true
