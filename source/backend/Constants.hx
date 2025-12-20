package backend;

class Constants {
    public static final NOTEBIND_NAMES:Array<String> = ['left_note', 'down_note', 'up_note', 'right_note'];
    public static final DIRECTION:Array<String> = ['left', 'down', 'up', 'right'];

	public static final VERBOSE:Bool = false;

    public static final SICK_WINDOW:Float = 45;
    public static final GOOD_WINDOW:Float = 90;
    public static final BAD_WINDOW:Float = 135;
    public static final SHIT_WINDOW:Float = 160;

    public static final COUNTDOWN_SPRITE_NAMES:Array<String> = ['ready', 'set', 'go'];
    public static final COUNTDOWN_SOUND_NAMES:Array<String> = ['three', 'two', 'one', 'go'];

	public static final SOUND_TRAY_CLIP_VALUES:Array<Int> = [20, 39, 55, 74, 92, 114, 137, 159, 179, 203];

	public static final CLICK_SOUNDS:Array<String> = [
        for (i in 1...8) 'keyClick$i'
    ];

    public static final WEEK_LOCK_PAD:Int = 4;

	public static final HEALTH_GAIN:Float = 0.025;
	public static final HEALTH_LOSS:Float = 0.05;
	public static final HEALTH_GAIN_HOLD:Float = 0.085;

	public static final SUSTAIN_EARLY_RELEASE_THRESHOLD:Float = 125;

	public static final CAMERA_LERP:Float = 2.4;
	
	public static final DEFAULT_NOTE_TYPE:String = 'default';

    public static final FORMATTED_KEYS:Map<FlxKey, String> = [
		ZERO => '0',
		ONE => '1',
		TWO => '2',
		THREE => '3',
		FOUR => '4',
		FIVE => '5',
		SIX => '6',
		SEVEN => '7',
		EIGHT => '8',
		NINE => '9',

		BACKSPACE => "Bksp",
		ESCAPE => 'Esc',
		CONTROL => 'Ctrl',
		CAPSLOCK => 'Caps',
		PRINTSCREEN => 'PrtScrn',
		PAGEUP => 'PgUp',
		PAGEDOWN => 'PgDown',

		PERIOD => '.',
		COMMA => ',',
		SEMICOLON => ';',
		GRAVEACCENT => '`',
		LBRACKET => '[',
		RBRACKET => ']',
		QUOTE => "'",
		SLASH => "/",
		NONE => '--'
	];

    public static final QUANTS:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];

	public static final LOOK_AHEAD_FACTOR:Float = 1.1;
	public static final SCROLLSPEED_FACTOR:Float = 0.45;

	public static final LOCK_ANIM_FRAMES:Array<{x:Float, color:Int}> = [
        {x: -10, color: FlxColor.RED},
        {x: 12, color: FlxColor.WHITE},
        {x: -4, color: FlxColor.RED},
        {x: 0, color: FlxColor.WHITE}
    ];

	public static final SIXTEEN_BY_NINE_RES:Array<String> = ['1024x576', '1152x648', '1280x720', '1366x768', '1600x900', '1920x1080', '2560x1440', '3840x2160'];
	public static final FOUR_BY_THREE_RES:Array<String> = ['1024x768', '1280x960', '1600x1200']; //One day... you will be supported

	public static final RESOLUTIONS:Array<String> = ['1024x576', /*'1024x768',*/ '1152x648', '1280x720', /*'1280x960',*/ '1366x768', '1600x900', /*'1600x1200',*/ '1920x1080', '2560x1440', '3840x2160'];

	public static final FULLSCREEN_TYPES:Array<String> = ['Windowed', 'Fullscreen', 'Borderless'];

	public static final VERSION:String = '1.0.0';
}