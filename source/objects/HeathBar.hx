package objects;

class HealthBar extends FlxSpriteGroup {
	public var playerBar:FlxSprite;
	public var opponentBar:FlxSprite;
	public var opponentSide:Bool = false;

	public var health:Float = 0.5;

	public var defaultColors:Bool = true;

	public function new(y:Float = 0, opponentSide:Bool = false):Void {
		super(0, y);

		this.opponentSide = opponentSide;

		var graphic = Path.image('uiSkins/${PlayState.uiSkin}/healthBar');
		if (graphic == null) Path.image('uiSkins/default/healthBar');

		add(playerBar = new FlxSprite(graphic));
		add(opponentBar = new FlxSprite(graphic));
		opponentBar.clipRect = FlxRect.get(0, 0, playerBar.width, playerBar.height);

		snapToTarget();

		screenCenter(X);
	}

	public function loadColors(player1:String, player2:String):Void {
		playerBar.color = defaultColors ? 0xFF00FF00 : FlxColor.fromString(Path.character(player1).healthbarColor);
		opponentBar.color = defaultColors ? 0xFFFF0000 : FlxColor.fromString(Path.character(player2).healthbarColor);
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		var thing:Float = 1 - health;

		opponentBar.clipRect.width = FlxMath.lerp(opponentBar.clipRect.width, playerBar.width * (opponentSide ? 1 - thing : thing), 10 * elapsed);
	}

	public function snapToTarget():Void {
		var thing:Float = 1 - health;
		opponentBar.clipRect.width = playerBar.width * (opponentSide ? 1 - thing : thing);
	}
}