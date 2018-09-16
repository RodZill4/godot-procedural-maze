tool
extends EditorScenePostImport

func post_import(scene):
	var filename = scene.filename
	var dir = filename.left(filename.find_last("/"))
	for c in scene.get_children():
		if c is MeshInstance:
			filename = "%s/%s.tres" % [ dir, c.name ]
			print("Saving "+filename)
			ResourceSaver.save(filename, c.mesh)
