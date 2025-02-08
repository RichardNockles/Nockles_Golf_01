extends Node3D

@onready var main_camera: Camera3D = $MainCamera
@onready var ball_start_pos: Node3D = $BallStartPos
@onready var golf_ball: RigidBody3D = $GolfBall
@onready var hole_position: Node3D = $HolePosition
@onready var power_slider: HSlider = $"../UI/HSlider"  # Reference to UI slider

var camera_sensitivity: float = 0.005  # Adjust for sensitivity
var camera_move_speed: float = 5.0  # Movement speed
var move_direction: Vector3 = Vector3.ZERO
var is_mouse_captured: bool = true  # Track if mouse is captured

func _ready():
    print("main_camera: ", main_camera)
    print("ball_start_pos: ", ball_start_pos)

    # Set initial camera position
    main_camera.global_transform = ball_start_pos.global_transform

    # Capture mouse for FPS-style control
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

    # Ensure UI elements don't block input
    power_slider.focus_mode = Control.FOCUS_NONE

func _input(event):
    if power_slider.has_focus():
        return  # Prevent camera movement if slider is focused

    if event is InputEventMouseMotion and is_mouse_captured:
        rotate_y(-event.relative.x * camera_sensitivity)  # Horizontal rotation
        main_camera.rotate_x(-event.relative.y * camera_sensitivity)  # Vertical rotation

        # Clamp the camera's vertical rotation to prevent flipping
        main_camera.rotation_degrees.x = clamp(main_camera.rotation_degrees.x, -45, 45)

    if event.is_action_pressed("ui_cancel"):  # Press Escape to release mouse
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        is_mouse_captured = false

    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        if power_slider.has_focus():
            print("Slider was focused, removing focus")
            power_slider.release_focus()  # Remove focus from the slider
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
            is_mouse_captured = true  # Re-capture mouse on click

func _process(delta):
    var input_direction = Vector3.ZERO

    # Capture movement input
    if Input.is_action_pressed("ui_up"):  # W Key
        input_direction -= transform.basis.z
    if Input.is_action_pressed("ui_down"):  # S Key
        input_direction += transform.basis.z
    if Input.is_action_pressed("ui_left"):  # A Key
        input_direction -= transform.basis.x
    if Input.is_action_pressed("ui_right"):  # D Key
        input_direction += transform.basis.x

    input_direction.y = 0  # Keep movement on the XZ plane
    input_direction = input_direction.normalized()

    # Move the camera
    global_transform.origin += input_direction * camera_move_speed * delta
