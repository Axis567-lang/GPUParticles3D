extends Node3D

var DOF_LENGTH = 250
var COLLISION_MASK = 1

func _physics_process(_delta):
	var start = global_position
	var end = start - global_transform.basis.z * DOF_LENGTH
	
	var rayParams = PhysicsRayQueryParameters3D.create(start, end, COLLISION_MASK)
	var result = get_world_3d().direct_space_state.intersect_ray(rayParams)
	
	if !result.is_empty():
		end = result.position
	
	GlobalRayPosition.ray_position = end
