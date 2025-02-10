extends MultiMeshInstance3D

@export var terrain: Node3D  # Assign your terrain node here
@export var instance_count: int = 100  # Number of trees to place
@export var min_range: Vector2 = Vector2(-50, -50)  # Min X, Z range
@export var max_range: Vector2 = Vector2(50, 50)  # Max X, Z range

func _ready():
    if not multimesh:
        print("MultiMesh is missing!")
        return

    multimesh.instance_count = instance_count
    var random = RandomNumberGenerator.new()
    
    for i in range(instance_count):
        var x = random.randf_range(min_range.x, max_range.x)
        var z = random.randf_range(min_range.y, max_range.y)
        var y = get_terrain_height(Vector3(x, 0, z))  # Get terrain height
        
        # Ensure trees only spawn on "HighGround"
        if is_highground(Vector3(x, y, z)):  
            var transform = Transform3D()
            transform.origin = Vector3(x, y, z)
            transform.basis = Basis.looking_at(get_terrain_normal(Vector3(x, y, z)), Vector3.UP)

            multimesh.set_instance_transform(i, transform)

func get_terrain_height(position: Vector3) -> float:
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(position + Vector3(0, 10, 0), position + Vector3(0, -10, 0))
    var result = space_state.intersect_ray(query)
    if result:
        return result.position.y
    return position.y  # Default to ground level

func get_terrain_normal(position: Vector3) -> Vector3:
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(position + Vector3(0, 10, 0), position + Vector3(0, -10, 0))
    var result = space_state.intersect_ray(query)
    if result:
        return result.normal
    return Vector3.UP  # Default to flat ground

func is_highground(position: Vector3) -> bool:
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(position + Vector3(0, 10, 0), position + Vector3(0, -10, 0))
    var result = space_state.intersect_ray(query)
    
    if result:
        var collider = result.collider
        if collider and collider.name == "HighGround":  # Check if hitting 'HighGround'
            return true
    return false
