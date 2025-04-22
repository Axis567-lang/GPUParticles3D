extends Node3D # Este script va en el nodo CameraRig (o cualquier Node3D que tenga la cámara como hijo)

# Velocidad de movimiento
@export var speed: float = 5.0

func _process(delta: float) -> void:
	var input_vector = Vector3.ZERO

	# Obtener input WASD
	if Input.is_key_pressed(KEY_W):
		input_vector.z -= 1
	if Input.is_key_pressed(KEY_S):
		input_vector.z += 1
	if Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_vector.x += 1

	# Normaliza para evitar que se mueva más rápido en diagonal
	input_vector = input_vector.normalized()

	# Mueve en relación con la orientación del nodo
	global_translate(transform.basis * input_vector * speed * delta)
