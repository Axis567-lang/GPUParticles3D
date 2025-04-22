extends MeshInstance3D

# Qué tan lejos lanzar el rayo desde la cámara
var DOF_LENGTH = 250;
# Con qué capas de colisión debe chocar el rayo
var COLLISION_MASK = 1;

func _ready() -> void:
	# Esto coloca el QuadMesh justo frente a la cámara (en local -Z)
	global_transform = get_parent().global_transform.translated(Vector3(0, 0, -1))

func _physics_process(_delta):
	# Calcula un punto frente a la cámara (o al objeto) 
	#  usando la dirección `-Z` de su transformada.
	var end = global_position - global_transform.basis.z * DOF_LENGTH
	
	# Crea los parámetros de un rayo que va desde 
	#  `global_position` hasta `end`, 
	#   sólo chocando con objetos del `COLLISION_MASK`.
	var rayParams = PhysicsRayQueryParameters3D.create(global_position, end, COLLISION_MASK)
	
	# Lanza el rayo y devuelve información si chocó con algo
	#  (posición, normal, collider, etc.).
	var ray = get_world_3d().direct_space_state.intersect_ray(rayParams)
	# Si el rayo choca con algo, usa ese punto como el "fin" del rayo. 
	#  Así no se va hasta el infinito.
	if !ray.is_empty():
		end = ray["position"]
		prints("Collided position: ", end)
	
	prints("Ray from:", global_position, "to:", end)
	
	# Toma el material del mesh y settea en el shader un parámetro llamado 
	#  `ray_position` (la posición donde el rayo golpeó o llegó).
	var sm = get_surface_override_material(0) as ShaderMaterial
	sm.set_shader_parameter("ray_position", end)
