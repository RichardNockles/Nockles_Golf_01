extends RigidBody3D

@export var hit_power: float = 5.0
@export var max_pullback_distance: float = 2.0

@onready var aiming_line: Path3D = $"../AimingLine"
@onready var power_slider: HSlider = $"../UI/HSlider"

var is_aiming: bool = false
var start_touch_position: Vector2 = Vector2.ZERO
var current_touch_position: Vector2 = Vector2.ZERO
var camera_direction: Vector3

func _ready():
    aiming_line.visible = false
    linear_damp = 0.5  # Add some damping
    angular_damp = 0.5  # Add some damping

    # Prevent the power slider from capturing WASD input
    power_slider.focus_mode = Control.FOCUS_NONE

func _input(event):
    if power_slider.has_focus():
        print("Power Slider has focus - Ignoring input")
        return  # Prevent input conflicts with UI elements

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        print("Mouse button pressed at:", event.position)
        if is_object_clicked(event.position):
            print("Golf ball clicked!")
            is_aiming = true
            start_touch_position = event.position
            camera_direction = -get_viewport().get_camera_3d().global_transform.basis.z
        else:
            print("Golf ball NOT clicked.")

    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and is_aiming:
        hit_ball()
        is_aiming = false

    elif event is InputEventMouseMotion and is_aiming:
        current_touch_position = event.position
        print("Mouse Moved to:", current_touch_position)  # Keep for debugging

func is_object_clicked(screen_position: Vector2) -> bool:
    var camera = get_viewport().get_camera_3d()
    var from = camera.project_ray_origin(screen_position)
    var to = from + camera.project_ray_normal(screen_position) * 5000  # Increase range

    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.new()
    query.from = from
    query.to = to
    query.collision_mask = 5  # Ensure correct layer for ball
    query.hit_from_inside = true
    query.collide_with_bodies = true

    var result = space_state.intersect_ray(query)

    if result and result.collider == self:
        print("Raycast hit the golf ball!")
        return true
    return false

func hit_ball():
    if not is_instance_valid(self):
        print("Error: Golf ball is not valid!")
        return

    var hit_direction = camera_direction
    hit_direction.y = 0
    hit_direction = hit_direction.normalized()

    var power_multiplier = clamp(power_slider.value / power_slider.max_value, 0.1, 1.0)
    var applied_power = clamp(hit_power * power_multiplier, 1.0, 15.0)  # Min & Max power

    apply_central_impulse(hit_direction * applied_power)

    print("Hit power applied:", applied_power)

func _process(_delta):
    if is_aiming:
        update_aiming_line()
    elif linear_velocity.length() < 0.05:  # Stop ball when velocity is low
        linear_velocity = Vector3.ZERO
        angular_velocity = Vector3.ZERO

func update_aiming_line():
    if not is_aiming:
        aiming_line.visible = false
        return

    aiming_line.visible = true
    aiming_line.curve.clear_points()

    var start_point = global_transform.origin
    var direction = camera_direction
    direction.y = 0
    direction = direction.normalized()

    var power_multiplier = power_slider.value / power_slider.max_value
    var end_point = start_point + direction * hit_power * power_multiplier

    aiming_line.curve.add_point(to_local(start_point))
    aiming_line.curve.add_point(to_local(end_point))
