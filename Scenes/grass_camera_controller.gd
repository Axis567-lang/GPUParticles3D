extends Node3D

@export var particles: GPUParticles3D
@export var camera: Camera3D

func _process(delta):
	if particles and camera:
		var inv_view_matrix = camera.global_transform.basis.inverse()
		particles.process_material.set_shader_parameter("u_inv_view_matrix", inv_view_matrix)
