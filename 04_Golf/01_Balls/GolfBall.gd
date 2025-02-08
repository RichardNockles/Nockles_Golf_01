extends RigidBody3D

@export var hit_power: float = 5.0
@export var max_pullback_distance: float = 2.0

@onready var aiming_line: Path3D = $"../AimingLine"
@onready var power_slider: HSlider = $"../UI/HSlider"

var is_aiming: bool = false
var start_touch_position: Vector2 = Vector2.ZERO
var current_touch_position: Vector2 = Vector2.ZERO
var camera_direction : Vector3

func _ready():
    aiming_line.visible = false
    linear_damp = 0.5  # Add some damping
    angular_damp = 0.5 # Add some damping

func _input(event):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        print("Mouse button pressed at:", event.position)
        if is_object_clicked(event.position):
            print("Golf ball clicked!")
            is_aiming = true
            start_touch_position = event.position
            # Capture the camera direction *when aiming starts*!
            camera_direction = -get_viewport().get_camera_3d().global_transform.basis.z
        else:
            print("Golf ball NOT clicked.")
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and is_aiming:
        hit_ball()
        is_aiming = false
    elif event is InputEventMouseMotion and is_aiming:
        current_touch_position = event.position
        print("Mouse Moved to:", current_touch_position) # Keep for debugging

func is_object_clicked(screen_position: Vector2) -> bool:
    var camera = get_viewport().get_camera_3d()
    var from = camera.project_ray_origin(screen_position)
    var to = from + camera.project_ray_normal(screen_position) * 1000

    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.new()
    query.from = from
    query.to = to
    query.collision_mask = 5  # "Ground" (2) + "Clickable" (3) = 5.  Correct!
    query.collide_with_bodies = true
    query.collide_with_areas = false

    var result = space_state.intersect_ray(query)

    print("Raycast result:", result)

    if result:
        print("Raycast hit something:", result.collider)
        if result.collider == self:
            print("Raycast hit the golf ball!")
            return true
        else:
            print("Raycast hit something else:", result.collider)
            return false
    else:
        print("Raycast hit nothing.")
        return false

func hit_ball():
    # Use the stored camera direction
    var hit_direction = camera_direction
    hit_direction.y = 0
    hit_direction = hit_direction.normalized()

    # Normalize the slider value to be between 0.0 and 1.0
    var power_multiplier = clamp(power_slider.value / power_slider.max_value, 0.0, 1.0)

    # Apply the impulse.
    var applied_power = hit_power * power_multiplier
    apply_central_impulse(hit_direction * applied_power)

    print("hit_power:", hit_power)
    print("power_slider.value:", power_slider.value)
    print("power_multiplier:", power_multiplier)
    print("applied_power:", applied_power)

func _process(_delta):
    if is_aiming:
        aiming_line.visible = true
        var start_point = global_transform.origin
        # Use the *stored* camera direction, not the current camera direction
        var direction = camera_direction
        direction.y = 0
        direction = direction.normalized()

        # Normalize the slider value
        var power_multiplier = power_slider.value / power_slider.max_value

        var end_point = start_point + direction * hit_power * power_multiplier

        # Add a small Y offset *before* converting to local coordinates
        start_point.y += 0.01  # Adjust this value as needed
        end_point.y += 0.01    # Adjust this value as needed

        aiming_line.curve.clear_points()
        aiming_line.curve.add_point(to_local(start_point))
        aiming_line.curve.add_point(to_local(end_point))
    else:
        aiming_line.visible = false
