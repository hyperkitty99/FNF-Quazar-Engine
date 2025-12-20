package objects;

class Countdown extends FlxSpriteGroup {
	public static var countdownArray:Array<FlxSprite> = [];
	public var conductor:Conductor;
	public var callback:Void -> Void;

	public function new(conductor:Conductor, callback:Void -> Void):Void {
		super();

		this.conductor = conductor;
		this.callback = callback;

		conductor.time = -conductor.beat.length * 5;
		conductor.beat.signal.add(countdown);
	}

	public function countdown():Void {
		if (conductor.beat.cur == 0) {
			conductor.beat.signal.remove(countdown);
			callback();
			destroy();
			return;
		}

		if (conductor.beat.cur > -4) {
			var sprite:String = Constants.COUNTDOWN_SPRITE_NAMES[conductor.beat.cur + 3];

			var graphic = Path.image('uiSkins/${PlayState.uiSkin}/$sprite');
			if (graphic == null) Path.image('uiSkins/default/$sprite');

			var countdownItem:FlxSprite = new FlxSprite(graphic);
			countdownItem.screenCenter();
			countdownArray.push(countdownItem);
			add(countdownItem);

			FlxTween.num(1, 0, conductor.beat.length * 0.001, {ease: FlxEase.cubeInOut, onComplete: destroySpr.bind(countdownItem)}, updateAlpha.bind(countdownItem));	
		}

		var sound:String = Constants.COUNTDOWN_SOUND_NAMES[conductor.beat.cur + 4];

		var audio = Path.sound('uiSkins/${PlayState.uiSkin}/$sound');
		if (audio == null) Path.sound('uiSkins/default/$sound');

		FlxG.sound.play(audio);
	}

	static function updateAlpha(sprite:FlxSprite, value:Float):Void {
		sprite.alpha = value;
	}

	static function destroySpr(sprite:FlxSprite, _:FlxTween):Void {
		countdownArray.remove(sprite);
		sprite.destroy();
	}
}