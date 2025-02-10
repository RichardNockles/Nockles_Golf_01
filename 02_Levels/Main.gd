extends Node3D

@onready var main_camera: Camera3D = $MainCamera
@onready var ball_start_pos: Node3D = $BallStartPos
@onready var golf_ball: RigidBody3D = $GolfBall
@onready var hole_position: Area3D = $HolePosition

var camera_sensitivity: float = 0.2  # Adjust for sensitivity
var camera_move_speed: float = 10.0  # Movement speed

func _ready():
    print("main_camera: ", main_camera)
    print("ball_start_pos: ", ball_start_pos)
    
    # Ensure the camera is positioned correctly
    position_camera()

func position_camera():
    var midpoint = (ball_start_pos.global_transform.origin + hole_position.global_transform.origin) / 2.0
    var direction = (hole_position.global_transform.origin - ball_start_pos.global_transform.origin).normalized()
    var distance = ball_start_pos.global_transform.origin.distance_to(hole_position.global_transform.origin) * 0.8
    distance = clamp(distance, 5, 25)

    var camera_position = midpoint - direction * distance + Vector3(0, 5, 0)
    main_camera.global_transform.origin = camera_position
    main_camera.look_at(midpoint, Vector3.UP)

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
    var input_direction = Vector3.ZERO

    # Get the golf_ball node within _process, as its position changes
    var golf_ball = get_node_or_null("GolfBall")
    if golf_ball != null:
        # Calculate the target position based on golf ball, distance, and height
        var target_position = golf_ball.global_position + Vector3(0, 2, 0) - main_camera.global_transform.basis.z.normalized() * 10

        # Smoothly move the camera towards the target position
        main_camera.global_transform.origin = main_camera.global_transform.origin.lerp(target_position, delta * 5.0) # Adjust speed with the last value
