extends Node

signal arrastre_finalizado(pieza: CharacterBody3D)

@onready var camara: Camera3D = get_viewport().get_camera_3d()

var arrastrando: CharacterBody3D = null
var arrastrando_offset: Vector3

func _snap_check() -> void:
	for rc: RayCast3D in arrastrando.get_node("rcs").get_children():
		if rc.is_colliding():
			var punto := rc.get_collision_point() - rc.global_position
			if not arrastrando.test_move(camara.transform, punto):
				arrastrando.get_node("modelo").position = punto
				return
	arrastrando.get_node("modelo").position = Vector3.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and arrastrando:
		# Movimiento de drag
		var m := camara.project_position(event.position, 0) - arrastrando_offset - arrastrando.global_position
		m.z = 0
		arrastrando.move_and_collide(m)
	
		# Verificacion de snap
		_snap_check()
		
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse : Vector2 = event.position
			var query := PhysicsRayQueryParameters3D.create(
				camara.project_ray_origin(mouse),
				camara.project_ray_origin(mouse) + camara.project_ray_normal(mouse) * 1000.0
			)
			var res := camara.get_world_3d().direct_space_state.intersect_ray(query)
			
			if res and res.collider is CharacterBody3D:
				arrastrando = res.collider
				arrastrando_offset = res.position - arrastrando.global_position
				
		elif arrastrando:
			var modelo = arrastrando.get_node_or_null("modelo")
			if modelo:
				arrastrando.global_position = modelo.global_position
				modelo.position = Vector3.ZERO
			
			arrastre_finalizado.emit(arrastrando)
			arrastrando = null
