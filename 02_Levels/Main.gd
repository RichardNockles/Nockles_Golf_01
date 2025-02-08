extends Node3D

@onready var main_camera: Camera3D = $MainCamera
@onready var ball_start_pos: Node3D = $BallStartPos
# No @onready for golf_ball

var camera_sensitivity: float = 0.2  # Adjust for sensitivity
var camera_move_speed: float = 10.0  # Movement speed

func _ready():
    print("main_camera: ", main_camera)
    print("ball_start_pos: ", ball_start_pos)
    # Don't print golf_ball here yet

    # Set initial camera position
    main_camera.global_transform = ball_start_pos.global_transform

    # Start the camera transition after a short delay
    await get_tree().create_timer(0.5).timeout
    transition_camera_to_target()

func transition_camera_to_target():
    # Create a tween
    var tween = get_tree().create_tween()
    tween.set_trans(Tween.TRANS_LINEAR)
    tween.set_ease(Tween.EASE_IN_OUT)

    # Get nodes here, inside the function
    var golf_ball = get_node("GolfBall")
    var hole_position = get_node("HolePosition")

    # Check if nodes are valid (good practice)
    if is_instance_valid(golf_ball) and is_instance_valid(hole_position):
        # Calculate target transform
        var target_transform = calculate_camera_transform(golf_ball.global_position, hole_position.global_position)

        # Animate the camera's transform
        tween.tween_property(main_camera, "global_transform", target_transform, 2.0)

        print("Camera final position: ", main_camera.global_transform.origin)
        print("Camera final rotation: ", main_camera.rotation_degrees)
    else:
        print("Error: Could not find GolfBall or HolePosition nodes.")

func calculate_camera_transform(ball_position: Vector3, target_position: Vector3) -> Transform3D:
    # Calculate the midpoint between the ball and the target
    var midpoint = (ball_position + target_position) / 2.0

    # Calculate the direction vector from the ball to the target
    var direction = (target_position - ball_position).normalized()

    # Calculate a suitable camera distance (adjust as needed)
    var distance = ball_position.distance_to(target_position) * 0.8
    distance = clamp(distance, 5, 25)

    # Calculate the camera position (offset from the ball)
    var camera_position = ball_position + Vector3(0, 2, 0) - direction * distance

    # Calculate the camera's look-at transform. Look at the MIDPOINT.
    var camera_transform = Transform3D().looking_at(midpoint, Vector3.UP)
    camera_transform.origin = camera_position

    return camera_transform

func _input(event):
    if event is InputEventMouseMotion:
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            var rotation_y = -event.relative.x * camera_sensitivity
            var rotation_x = -event.relative.y * camera_sensitivity

            # Rotate the camera around the Y axis (left/right)
            main_camera.rotate_y(deg_to_rad(rotation_y))

            # Rotate the camera around the X axis (up/down), clamping the angle
            main_camera.rotation_degrees.x = clamp(main_camera.rotation_degrees.x + rotation_x, -89, 89) # Limit vertical rotation

    if event.is_action_pressed("ui_cancel"): # Usually the 'Escape' key
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        
func _process(delta):
    # Get the golf_ball node within _process, as its position changes
    var golf_ball = get_node_or_null("GolfBall")
    if golf_ball != null:
        # Calculate the target position based on golf ball, distance, and height
        var target_position = golf_ball.global_position + Vector3(0, 2, 0) - main_camera.global_transform.basis.z.normalized() * 10

        # Smoothly move the camera towards the target position
        main_camera.global_transform.origin = main_camera.global_transform.origin.lerp(target_position, delta * 5.0) # Adjust speed with the last value

func _on_hole_trigger_area_3d_body_entered(body):
    if body is RigidBody3D and body.name == "GolfBall":
        print("Ball in the hole!")
        # Add your hole completion logic here
        body.set_collision_layer_value(2, false)
        body.set_collision_mask_value(2, false)
        body.set_freeze_enabled(true)
