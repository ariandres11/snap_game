extends CharacterBody3D
class_name Ficha3D

@export var radio_snap: float = 3.0
@export var velocidad_arrastre: float = 25.0

var arrastrando: bool = false
var camara: Camera3D
var plano_arrastre: Plane
var z_fijo: float = 0.0

func _ready() -> void:
	camara = get_viewport().get_camera_3d()
	add_to_group("fichas")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			arrastrando = true
			z_fijo = global_position.z
			plano_arrastre = Plane(Vector3.BACK, global_position)
		else:
			arrastrando = false
			_intentar_snap()

func _physics_process(delta: float) -> void:
	if arrastrando:
		var pos_mouse := get_viewport().get_mouse_position()
		var pos_destino = plano_arrastre.intersects_ray(camara.project_ray_origin(pos_mouse), camara.project_ray_normal(pos_mouse))
		pos_destino.z = z_fijo
		velocity = (pos_destino - global_position) * velocidad_arrastre
		velocity.z = (z_fijo - global_position.z) / delta
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		move_and_slide()

func _intentar_snap() -> void:
	var otra = _obtener_ficha_mas_cercana()
	if not otra: return
	
	var c1 = find_child("CollisionShape3D") as CollisionShape3D
	var c2 = otra.find_child("CollisionShape3D") as CollisionShape3D
	if not c1 or not c2: return
	
	var dir = global_position - otra.global_position
	dir.z = 0
	if dir.length() <= radio_snap and dir.length() > 0.001:
		dir = dir.normalized()
		
		# Obtenemos el tamaño real (AABB) de cada figura para respetar sus dimensiones exactas
		var size1 = c1.shape.get_aabb().size
		var size2 = c2.shape.get_aabb().size
		
		# Calculamos la distancia exacta de separación basada en el tamaño de ambas piezas
		var distancia_exacta = (size1.x * abs(dir.x) + size1.z * abs(dir.z) + size2.x * abs(dir.x) + size2.z * abs(dir.z)) * 0.5
		
		global_position = otra.global_position + (dir * distancia_exacta)
		global_position.z = z_fijo

func _obtener_ficha_mas_cercana() -> Ficha3D:
	var mas_cercana: Ficha3D = null
	var menor_distancia = INF
	for ficha in get_tree().get_nodes_in_group("fichas"):
		if ficha != self:
			var dist = global_position.distance_to(ficha.global_position)
			if dist < menor_distancia:
				menor_distancia = dist
				mas_cercana = ficha
	return mas_cercana
