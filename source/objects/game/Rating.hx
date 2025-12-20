package objects.game;

class Rating {
	static var zIndexCounter:Int = 0;

	public var name:String;
	public var percent:Float;

	public function new(name:String, percent:Float):Void {
		this.name = name;
		this.percent = percent;
	}

	public static function add(name:String, percent:Float):Rating {
		return new Rating(name, percent);
	}

	public static function saveWeekScore(score:Int):Void {
		if (PlayState.botplay || PlayState.practiceMode) return;
		
		Data.completedWeeks.set(WeekData.weeks[PlayState.curWeek], true);
		Highscore.saveWeekScore(WeekData.weeks[PlayState.curWeek], PlayState.difficulty, PlayState.weekScore == 0 ? score : PlayState.weekScore);
		FlxG.save.data.completedWeeks = Data.completedWeeks;
		FlxG.save.flush();

		PlayState.weekScore = 0;
	}

	public static function saveFreeplayScore(score:Int, percent:Float):Void {
		if (PlayState.botplay || PlayState.practiceMode) return;
		Highscore.saveScore(PlayState.curSong, PlayState.difficulty, score, percent);
	}

	public static function recalculate():Void {
		if (game.totalPlayed == 0) return;

		game.percent = FlxMath.bound(game.totalHit / game.totalPlayed, 0, 1);

		game.curRating = game.ratings[game.ratings.length - 1].name;

		for (rat in game.ratings) {
			if (game.percent < rat.percent) {
				game.curRating = rat.name;
				break;
			}
    	}
	}

	public static function create(ratingName:String = null):Void {
		zIndexCounter++;

		if (ratingName != null) {
			var ratingGraphic = Path.image('uiSkins/${PlayState.uiSkin}/$ratingName');
			if (ratingGraphic == null) Path.image('uiSkins/default/$ratingName');

			var rating:FlxSprite = game.ui.comboGroup.recycle(FlxSprite, newRating);	
			rating.loadGraphic(ratingGraphic);
			rating.scale.set(0.7, 0.7);
			rating.updateHitbox();
			rating.screenCenter();
			rating.offset.set(35 - Data.comboOffsets[0], 25 - Data.comboOffsets[1]);
			rating.velocity.set(-FlxG.random.int(0, 10), -FlxG.random.int(140, 175));
			rating.acceleration.y = 550;
			rating.zIndex = zIndexCounter;

			FlxTween.num(1, 0, 0.2, {type: ONESHOT, onComplete: onTweenComplete.bind(rating), startDelay: game.beatLength * 0.001}, updateAlpha.bind(rating));
		}

		if (game.combo == 0 || game.combo >= 10) {
			var numArr:Array<String> = Std.string(game.combo).lpad('0', 3).split('');
			numArr.reverse();

			for (i => num in numArr) {
				var numGraphic = Path.image('uiSkins/${PlayState.uiSkin}/num$num');
				if (numGraphic == null) Path.image('uiSkins/default/num$num');

				var comboNum:FlxSprite = game.ui.comboGroup.recycle(FlxSprite, newRating);
				comboNum.loadGraphic(numGraphic);
				comboNum.scale.set(0.55, 0.55);
				comboNum.updateHitbox();
				comboNum.screenCenter();
				comboNum.offset.set((comboNum.width + 5) * i + 50 - Data.comboOffsets[0], -(comboNum.height + 25) - Data.comboOffsets[1]);
				comboNum.velocity.set(FlxG.random.float(-5, 5), -FlxG.random.int(140, 160));
				comboNum.acceleration.y = FlxG.random.int(200, 300);
				comboNum.zIndex = zIndexCounter;

				FlxTween.num(1, 0, 0.2, {type: ONESHOT, onComplete: onTweenComplete.bind(comboNum), startDelay: game.beatLength * 0.001}, updateAlpha.bind(comboNum));
			}
		}

		game.ui.comboGroup.sort(Util.sortByZIndex);
	}

	static function onTweenComplete(sprite:FlxSprite, tween:FlxTween):Void {
		sprite.kill();
	}

	static function updateAlpha(sprite:FlxSprite, value:Float):Void {
		sprite.alpha = value;
	}

	static function newRating():FlxSprite {
		var rating:FlxSprite = new FlxSprite();
		rating.moves = true;
		return rating;
	}
}