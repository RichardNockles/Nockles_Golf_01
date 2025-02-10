extends Node3D

@onready var main_camera: Camera3D = $MainCamera
@onready var ball_start_pos: Node3D = $BallStartPos
@onready var golf_ball: RigidBody3D = $GolfBall
@onready var hole_position: Area3D = $HolePosition
@onready var power_slider: HSlider = $UI/PowerSlider
@onready var swing_button: Button = $UI/SwingButton

var camera_sensitivity: float = 0.005  # Adjust for sensitivity
var camera_move_speed: float = 5.0  # Movement speed
var max_power = 1000.0
var is_mouse_captured: bool = true  # Track if mouse is captured
var is_aiming: bool = false

func _ready():
    print("main_camera: ", main_camera)
    print("ball_start_pos: ", ball_start_pos)

    # Set initial camera position
    golf_ball.global_transform.origin = ball_start_pos.global_transform.origin
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    power_slider.focus_mode = Control.FOCUS_NONE
    swing_button.connect("pressed", Callable(self, "_on_SwingButton_pressed"))

func _input(event):
    if power_slider.has_focus():
        return  # Prevent camera movement if slider is focused

    if event is InputEventMouseMotion and is_mouse_captured:
        rotate_y(-event.relative.x * camera_sensitivity)  # Horizontal rotation
        main_camera.rotate_x(-event.relative.y * camera_sensitivity)  # Vertical rotation
        main_camera.rotation_degrees.x = clamp(main_camera.rotation_degrees.x, -45, 45)

    if event.is_action_pressed("ui_cancel"):  # Escape to release mouse
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        is_mouse_captured = false

    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        is_mouse_captured = true  # Re-capture mouse on click

func _process(delta):
    var input_direction = Vector3.ZERO

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
    global_transform.origin += input_direction * camera_move_speed * delta

func _on_SwingButton_pressed():
    var power = power_slider.value / power_slider.max_value * max_power
    var direction = -global_transform.basis.z.normalized()
    golf_ball.apply_impulse(Vector3.ZERO, direction * power)
    print("Hit Ball with Power:", power)

func _on_Hole_body_entered(body):
    if body.name == "GolfBall":
        print("Ball in the hole!")
        body.set_freeze_enabled(true)  # Stops the ball
        await get_tree().create_timer(1.5).timeout
        body.set_freeze_enabled(false)
        body.global_transform.origin = ball_start_pos.global_transform.origin
