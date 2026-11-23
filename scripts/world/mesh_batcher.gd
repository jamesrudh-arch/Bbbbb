class_name MeshBatcher
extends RefCounted
## Merges the many small MeshInstance3Ds a procedural building emits into one
## ArrayMesh per material.
##
## The city was emitting ~17,000 individual meshes, which is ~17,000 draw calls.
## That is unworkable on an iPhone and it made the software renderer time out.
## Boxes and quads are cheap to merge: expand every child's mesh into vertices in
## the parent's space, bucket by material, and hand each bucket to SurfaceTool.
##
## Usage:
##   var b := MeshBatcher.new()
##   b.add(size, offset, material, transform3d)   # instead of a MeshInstance3D
##   b.commit(body)

var _buckets: Dictionary = {}   # material -> Array[Array] of {verts, normals, uvs, indices}
var _tris := 0

## Add a box.
func add_box(size: Vector3, offset: Vector3, mat: Material, xform: Transform3D = Transform3D.IDENTITY) -> void:
	var bm := BoxMesh.new()
	bm.size = size
	_push_mesh(bm, mat, xform * Transform3D(Basis.IDENTITY, offset))

## Add a quad facing +Z (rotated by `xform`).
func add_quad(size: Vector2, offset: Vector3, mat: Material, xform: Transform3D = Transform3D.IDENTITY) -> void:
	var qm := QuadMesh.new()
	qm.size = size
	_push_mesh(qm, mat, xform * Transform3D(Basis.IDENTITY, offset))

func _push_mesh(mesh: Mesh, mat: Material, xform: Transform3D) -> void:
	if mat == null:
		return
	var key: int = mat.get_instance_id()
	if not _buckets.has(key):
		_buckets[key] = {"mat": mat, "st": SurfaceTool.new(), "n": 0}
	var bucket: Dictionary = _buckets[key]
	var st: SurfaceTool = bucket["st"]
	if bucket["n"] == 0:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for si in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(si)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var normals = arr[Mesh.ARRAY_NORMAL]
		var idx = arr[Mesh.ARRAY_INDEX]
		if idx == null or (idx as PackedInt32Array).is_empty():
			continue
		var uvs = arr[Mesh.ARRAY_TEX_UV]
		var nb := xform.basis.inverse().transposed()
		for i in (idx as PackedInt32Array):
			st.set_normal((nb * (normals[i] as Vector3)).normalized())
			if uvs != null:
				st.set_uv(uvs[i])
			st.add_vertex(xform * verts[i])
		_tris += (idx as PackedInt32Array).size() / 3
	bucket["n"] = int(bucket["n"]) + 1

## Build the merged meshes and attach them to `parent`.
func commit(parent: Node3D) -> int:
	var made := 0
	for key in _buckets:
		var bucket: Dictionary = _buckets[key]
		var st: SurfaceTool = bucket["st"]
		if int(bucket["n"]) == 0:
			continue
		st.generate_tangents()
		var mesh: ArrayMesh = st.commit()
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = bucket["mat"]
		parent.add_child(mi)
		made += 1
	_buckets.clear()
	return made

func triangle_count() -> int:
	return _tris
