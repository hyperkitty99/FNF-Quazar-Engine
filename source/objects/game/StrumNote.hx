package objects.game;

class StrumNote extends NoteSprite {
	public var autoReset:Bool = true;

	public function new(data:Int = 0, line:Strumline):Void {
		super(data, line);

		onSkinChange();
		playAnim('strum $dir');

		animation.onFinish.add(onFinish);
	}

	public function onSkinChange():Void {
		loadSkin(strumline.skinData);
		scale.set(
			(strumline.skinData.meta.strumScale[0] ?? 1) * (strumline.skinData.meta.scale[0] ?? 1),
			(strumline.skinData.meta.strumScale[1] ?? 1) * (strumline.skinData.meta.scale[1] ?? 1)
		);
		updateHitbox();
	}

	function onFinish(name:String):Void {
		if (name == 'confirm $dir' && autoReset) {
			resetAnim();
		}
	}

	public function confirm(autoReset:Bool = true):Void {
		playAnim('confirm $dir', true);
		this.autoReset = autoReset;
	}

	public function press():Void {
		playAnim('press $dir');
	}

	public function resetAnim():Void {
		playAnim('strum $dir');
	}

	@:inheritDoc(flixel.animation.FlxAnimationController.play)
	override function playAnim(name:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void {
		animation.play(name, force, reversed, frame);
		centerOrigin();

		if (offsets.exists(name)) {
			offset.set(
				(frameWidth - width) * 0.5 + ((offsets[name][0] ?? 0) * scale.x),
				(frameHeight - height) * 0.5 + ((offsets[name][1] ?? 0) * scale.y)
			);
		} else {
			centerOffsets();
		}
	}
}