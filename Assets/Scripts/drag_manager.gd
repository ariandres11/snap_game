extends Node

signal arrastre_finalizado(pieza: CharacterBody3D)

@onready var camara: Camera3D = get_viewport().get_camera_3d()

var arrastrando: CharacterBody3D = null
var plano_arrastre: Plane

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse := get_viewport().get_mouse_position()
			var query := PhysicsRayQueryParameters3D.create(
				camara.project_ray_origin(mouse),
				camara.project_ray_origin(mouse) + camara.project_ray_normal(mouse) * 1000.0
			)
			var res := camara.get_world_3d().direct_space_state.intersect_ray(query)
			
			if res and res.collider is CharacterBody3D:
				arrastrando = res.collider
				plano_arrastre = Plane(Vector3.BACK, arrastrando.global_position)
		elif arrastrando:
			var modelo = arrastrando.get_node_or_null("modelo")
			if modelo:
				arrastrando.global_position = modelo.global_position
				modelo.position = Vector3.ZERO
			
			arrastre_finalizado.emit(arrastrando)
			arrastrando = null

func _physics_process(_delta: float) -> void:
	if arrastrando and camara:
		var pos_mouse := get_viewport().get_mouse_position()
		var origen := camara.project_ray_origin(pos_mouse)
		var normal := camara.project_ray_normal(pos_mouse)
		
		var pos_3d = plano_arrastre.intersects_ray(origen, normal)
		if pos_3d != null:
			var move: Vector3 = pos_3d - arrastrando.global_position
			move.z = 0.0
			arrastrando.move_and_collide(move)
