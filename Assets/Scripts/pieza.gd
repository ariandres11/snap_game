extends CharacterBody3D
class_name Ficha3D

## Distancia máxima (metros) para activar la imantación
@export var radio_snap: float = 1.5
## Velocidad con la que la ficha sigue al cursor
@export var velocidad_arrastre: float = 25.0

# Variables para el control de arrastre
var arrastrando: bool = false
var camara: Camera3D
var plano_arrastre: Plane
var z_fijo: float = 0.0

# Variables del sistema de encaje
var posicion_objetivo_snap: Vector3
var hay_snap: bool = false

# Datos geométricos locales extraídos de las caras
var centroides_locales: Array[Vector3] = []
var normales_locales: Array[Vector3] = []

const GRUPO_PUNTOS_SNAP = "puntos_snap"

func _ready() -> void:
	camara = get_viewport().get_camera_3d()
	add_to_group(GRUPO_PUNTOS_SNAP)
	
	_extraer_geometria_y_crear_raycasts()

## 1. Extrae caras, normales y centroides de la colisión e instancia RayCasts de detección
func _extraer_geometria_y_crear_raycasts() -> void:
	var col: CollisionShape3D = find_child("CollisionShape3D", true, false)
	
	if col and col.shape is ConcavePolygonShape3D:
		var caras: PackedVector3Array = (col.shape as ConcavePolygonShape3D).data
		
		for i in range(0, caras.size(), 3):
			var v0 := caras[i]
			var v1 := caras[i + 1]
			var v2 := caras[i + 2]
			
			var centroide := (v0 + v1 + v2) / 3.0
			var normal := (v1 - v0).cross(v2 - v0).normalized()
			
			centroides_locales.append(centroide)
			normales_locales.append(normal)
			
			# Creamos los RayCast3D en cada centroide orientados según la normal
			var rc := RayCast3D.new()
			rc.name = "RayCast_Cara_" + str(i / 3)
			rc.position = centroide
			rc.target_position = normal
			col.add_child(rc)
	else:
		push_warning("No se encontró un CollisionShape3D con ConcavePolygonShape3D.")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_intentar_iniciar_arrastre()
		else:
			if arrastrando:
				_finalizar_arrastre()

func _physics_process(delta: float) -> void:
	if not arrastrando or not camara:
		return
		
	var pos_mouse := get_viewport().get_mouse_position()
	var origen_rayo := camara.project_ray_origin(pos_mouse)
	var dir_rayo := camara.project_ray_normal(pos_mouse)
	
	# Intersección con el plano X-Y
	var pos_3d_destino = plano_arrastre.intersects_ray(origen_rayo, dir_rayo)
	
	if pos_3d_destino != null:
		pos_3d_destino.z = z_fijo # Congelamos el eje Z
		
		_evaluar_snapping_por_caras(pos_3d_destino)
		
		var pos_objetivo = posicion_objetivo_snap if hay_snap else pos_3d_destino
		pos_objetivo.z = z_fijo
		
		var vector_hacia_objetivo = pos_objetivo - global_position
		
		# Si está en el rango inmediato del snap, encaja con precisión
		if hay_snap and vector_hacia_objetivo.length() < 0.05:
			global_position = pos_objetivo
			velocity = Vector3.ZERO
		else:
			# Usa move_and_slide() para colisionar físicamente contra otras fichas
			velocity = vector_hacia_objetivo * velocidad_arrastre
			velocity.z = (z_fijo - global_position.z) / delta # Fuerza mantener el Z estático
			move_and_slide()

## 2. Evalúa cercanía comprobando únicamente caras enfrentadas (normales opuestas)
func _evaluar_snapping_por_caras(pos_simulada: Vector3) -> void:
	hay_snap = false
	var menor_distancia := radio_snap
	var otras_fichas = get_tree().get_nodes_in_group(GRUPO_PUNTOS_SNAP)
	var basis_mi = global_transform.basis
	
	for otra in otras_fichas:
		if otra == self or is_ancestor_of(otra):
			continue
			
		if "centroides_locales" in otra and "normales_locales" in otra:
			var basis_otra = otra.global_transform.basis
			var pos_otra = otra.global_position
			
			for i in centroides_locales.size():
				var c_loc_mi = centroides_locales[i]
				var n_loc_mi = normales_locales[i]
				
				var c_glob_mi = pos_simulada + (basis_mi * c_loc_mi)
				var n_glob_mi = (basis_mi * n_loc_mi).normalized()
				
				for j in otra.centroides_locales.size():
					var c_loc_otra = otra.centroides_locales[j]
					var n_loc_otra = otra.normales_locales[j]
					
					var c_glob_otra = pos_otra + (basis_otra * c_loc_otra)
					var n_glob_otra = (basis_otra * n_loc_otra).normalized()
					
					# Si el producto punto no es menor a -0.7, las caras no están mirándose de frente
					if n_glob_mi.dot(n_glob_otra) > -0.7:
						continue
					
					var distancia := c_glob_mi.distance_to(c_glob_otra)
					
					if distancia < menor_distancia:
						menor_distancia = distancia
						
						# Compensación exacta para pegar cara con cara
						var offset_mi_cara = (basis_mi * c_loc_mi)
						posicion_objetivo_snap = c_glob_otra - offset_mi_cara
						hay_snap = true

func _intentar_iniciar_arrastre() -> void:
	var pos_mouse := get_viewport().get_mouse_position()
	var origen := camara.project_ray_origin(pos_mouse)
	var dir := camara.project_ray_normal(pos_mouse)
	
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origen, origen + dir * 1000.0)
	var resultado := space_state.intersect_ray(query)
	
	if resultado and (resultado.collider == self or is_ancestor_of(resultado.collider)):
		arrastrando = true
		z_fijo = global_position.z
		plano_arrastre = Plane(Vector3.BACK, global_position)

func _finalizar_arrastre() -> void:
	arrastrando = false
	if hay_snap:
		global_position = posicion_objetivo_snap
		global_position.z = z_fijo
	velocity = Vector3.ZERO
