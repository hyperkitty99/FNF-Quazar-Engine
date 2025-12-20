package objects.game;

class Note extends NoteSprite {
	public var time:Float = 0;
	public var length:Float = 0;
	public var type:String = 'default';

	public var noteType:BaseNote;

	public var parent:StrumNote;
	public var sustain:Sustain;
	public var sustainCover:SustainCover;
	public var spark:Spark;
	public var sustainLight:SustainLight;

	public var sustaining:Bool = false;
	public var hittable:Bool = true;

    public var healthGain:Float = 0.025;
    public var healthLoss:Float = 0.05;
    public var healthGainHold:Float = 0.085;

	public var mustPress:Bool = true;
	public var hitCausesMiss:Bool = false;
	public var hitByOpponent:Bool = true;

	public function setup(json:NoteJSON, strumline:Strumline):Void {
		y = FlxG.height * 4 / camera.zoom;
		sustaining = false;
		hittable = visible = true;

		data = json.data ?? 0;
		time = json.time ?? 0;
		length = json.length ?? 0;
		type = json.type ?? 'default';
		if (type == '') type = 'default';

		playAnim('note $dir');

		parent = strumline.strums[data % strumline.strums.length];

		if (parent.strumline.skinData.meta.hasSustainCovers) {
			sustainCover = parent.strumline.sustainCovers[data % parent.strumline.sustainCovers.length];
		}

		if (parent.strumline.skinData.meta.hasSparks) {
			spark = parent.strumline.sparks[data % parent.strumline.sparks.length];
		}

		if (parent.strumline.skinData.meta.hasSustainLights) {
			sustainLight = parent.strumline.sustainLights[data % parent.strumline.sustainLights.length];
		}

		if (length > 0) {
			sustain = parent.strumline.sustains.recycle(Sustain, newSustain).setup(this);
			sustain.height = length * (game.scrollSpeed * Constants.SCROLLSPEED_FACTOR);
		}

		noteType = NoteType.get(type);

		if (noteType != null) {
			healthGain = noteType.healthGain;
			healthLoss = noteType.healthLoss;
			healthGainHold = noteType.healthGainHold;
			mustPress = noteType.mustPress;
			hitCausesMiss = noteType.hitCausesMiss;
			hitByOpponent = noteType.hitByOpponent;
		}

		onSkinChange();
	}

	public function onSkinChange():Void {
		loadSkin((noteType != null && noteType.skin != null) ? noteType.skin : parent.strumline.skinData);

		if (parent.strumline.skinData.meta.hasSustainCovers) {
			sustainCover.loadSkin((noteType != null && noteType.skin != null) ? noteType.skin : parent.strumline.skinData);
		}

		if (parent.strumline.skinData.meta.hasSparks) {
			spark.loadSkin((noteType != null && noteType.skin != null) ? noteType.skin : parent.strumline.skinData);
		}

		if (parent.strumline.skinData.meta.hasSustainLights) {
			sustainLight.loadSkin((noteType != null && noteType.skin != null) ? noteType.skin : parent.strumline.skinData);
		}

		var prevHeight:Float = 0;
		if (sustain != null && length > 0) {
			prevHeight = sustain.height;
			sustain.onSkinChange(this);
			sustain.height = prevHeight; //no clue why but the height resets upon changing the texture
		}
	}

	function newSustain():Sustain {
		return new Sustain();
	}

	public function hit():Void {
		if (noteType != null) {
			noteType.onHit(this);
		}

		(type == 'gf' ? game.stage.gf : parent.strumline.character).sing(dir);

		hittable = false;

		if (parent.strumline.player) {
			game.health += healthGain;
		}

		if (length > 0) {
			if (parent.strumline.skinData.meta.hasSustainCovers) {
				sustainCover.start();
				sustainCover.setPosition(x + (parent.width - sustainCover.width) * 0.5, parent.y);
				sustainCover.angle = sustain.angle;
			}

			if (parent.strumline.skinData.meta.hasSparks) {
				spark.start();
				spark.setPosition(x + (parent.width - spark.width) * 0.5, parent.y + (parent.width - spark.width) * 0.5);
			}

			if (parent.strumline.skinData.meta.hasSustainLights) {
				sustainLight.start();
				sustainLight.setPosition(sustain.x, parent.y + (parent.height * (Data.downScroll ? 0.65 : 0.5)) + sustainLight.offset.y);
				sustainLight.angle = sustain.angle;
			}

			parent.confirm(false);
			sustaining = true;
			visible = false;
		} else {
			parent.confirm(true);
			kill();
		}
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		setPosition(parent.x, parent.y - (game.conductor.time - time) * (game.scrollSpeed * Constants.SCROLLSPEED_FACTOR) * (Data.downScroll ? -1 : 1));

		sustaining ? holding(elapsed) : hitting();

		var missedNote:Bool = !parent.strumline.autoHit && hittable && (game.conductor.time >= time + ((FlxG.height / camera.zoom) * 0.5) / (game.scrollSpeed * Constants.SCROLLSPEED_FACTOR));
		var offScreen:Bool = game.conductor.time >= time + length + ((FlxG.height / camera.zoom) * 0.5) / (game.scrollSpeed * Constants.SCROLLSPEED_FACTOR);

		if (missedNote && mustPress) {
			miss();
		}

		if (offScreen) {
			kill();
		}
	}

	public function holding(elapsed:Float):Void {
		if (noteType != null) {
			noteType.onHold(this);
		}

		(type == 'gf' ? game.stage.gf : parent.strumline.character).holdTimer = 0;

		if (sustain != null) {
        	sustain.height = Math.max((time + length) - game.conductor.time, 0) * (game.scrollSpeed * Constants.SCROLLSPEED_FACTOR);
			sustain.setPosition(x + (width - sustain.width) * 0.5, Data.downScroll ? parent.y - sustain.height : parent.y);

			if (parent.strumline.skinData.meta.hasSustainLights) {
				var leHeight = sustain.height <= 115 ? sustain.height * (sustainLight.initialHeight / 115) : sustainLight.initialHeight;
				sustainLight.scale.y = (Data.downScroll ? -leHeight : leHeight) / sustainLight.frameHeight;

				sustainLight.setPosition(sustain.x, parent.y + (parent.height * (Data.downScroll ? 0.65 : 0.5)) + sustainLight.offset.y);
				sustainLight.angle = sustain.angle;
			}

			if (parent.strumline.skinData.meta.hasSustainCovers) {
				sustainCover.setPosition(x + (parent.width - sustainCover.width) * 0.5, parent.y);
				sustainCover.angle = sustain.angle;
			}

			if (parent.strumline.skinData.meta.hasSparks) {
				spark.setPosition(x + (parent.width - spark.width) * 0.5, parent.y + (parent.width - spark.width) * 0.5);
			}
		}

		if (parent.strumline.player) {
			var allowedEarlyRelease:Bool = ((time + length) - game.conductor.time) <= 125;

			if (!parent.strumline.autoHit) game.score += Std.int((noteType != null ? noteType.scoreGainHold : 250) * elapsed);
			game.health += healthGainHold * elapsed;

			if (!parent.strumline.autoHit) {
				if (Data.keybinds[Constants.NOTEBIND_NAMES[data % Constants.NOTEBIND_NAMES.length]].foreach(unpressedKey)) {
					if (noteType != null) {
						noteType.onHoldRelease(this);
					}

					if (parent.strumline.skinData.meta.hasSustainCovers) {
						sustainCover.alpha = 0;
					}

					if (parent.strumline.skinData.meta.hasSparks) {
						spark.alpha = 0;
					}

					if (parent.strumline.skinData.meta.hasSustainLights) {
						sustainLight.alpha = 0;
					}

					if (mustPress && !allowedEarlyRelease) {
						miss();
					} else {
						var char = type == 'gf' ? game.stage.gf : parent.strumline.character;
						char.holdTimer = (char.stepLength * 0.001 * char.singDuration) * 0.75;
					}
					kill();
				}
			}

			if (game.conductor.time >= time + length) {
				var char = type == 'gf' ? game.stage.gf : parent.strumline.character;
				char.holdTimer = (char.stepLength * 0.001 * char.singDuration) * 0.75;
				SustainCover.spawn(parent, data, (noteType != null && noteType.skin != null) ? noteType.skin : null);
				parent.press();
			}
		}

		if (game.conductor.time >= time + length) {
			if (noteType != null) {
				noteType.onHoldFinish(this);
			}

			if (parent.strumline.autoHit) {
				parent.resetAnim();
				SustainCover.spawn(parent, data, (noteType != null && noteType.skin != null) ? noteType.skin : null);
			}
			kill();
		}
	}

	public function hitting():Void {
		if (sustain != null) {
			sustain.height = length * (game.scrollSpeed * Constants.SCROLLSPEED_FACTOR);
			sustain.setPosition(x + (width - sustain.width) * 0.5, Data.downScroll ? y - sustain.height : y);
		}

		if (parent.strumline.autoHit && hitByOpponent && game.conductor.time >= time) {
			hit();
		}
	}

	public function judge(diff:Float, id:Int):Void {
		if (hitCausesMiss) {
			miss();
			return;
		}

		var scoreModifier:Int = noteType != null ? noteType.scoreGainSick : 350;

		var ratingName:String = switch diff {
			case(_ <= Constants.SICK_WINDOW + PlayerControls.safeMS) => true:
				if (game.ui.curStrumline.skinData.meta.hasNoteSplashes) {
					NoteSplash.spawn(game.ui.curStrumline.strums[id]);
				}
				game.totalHit += 1;
				'sick';
			case(_ <= Constants.GOOD_WINDOW + PlayerControls.safeMS) => true:
				scoreModifier = noteType != null ? noteType.scoreGainGood : 200;
				game.totalHit += 0.67;
				'good';
			case(_ <= Constants.BAD_WINDOW + PlayerControls.safeMS) => true:
				scoreModifier = noteType != null ? noteType.scoreGainBad : 100;
				game.totalHit += 0.34;
				if (type != 'gf') game.stage.gf.checkComboDrop(game.combo);
				game.combo = 0;
				'bad';
			case(_ <= Constants.SHIT_WINDOW + PlayerControls.safeMS) => true:
				scoreModifier = noteType != null ? noteType.scoreGainShit : 50;
				if (type != 'gf') game.stage.gf.checkComboDrop(game.combo);
				game.combo = 0;
				'shit';
			default:
				'miss';
		};

		if (ratingName == 'miss') {
			miss();
			return;
		}

		game.ui.curStrumline.voices.volume = 1;

		game.combo++;
		game.totalPlayed++;

		Rating.recalculate();
		game.score += scoreModifier;

		if (type != 'gf') game.stage.gf.checkCombo(game.combo);

		Rating.create(ratingName);
	}

	public function miss(count:Bool = true):Void {
		var prevCombo:Int = game.combo;

		if (noteType != null && count) {
			noteType.onMiss(this);
		}

		hittable = false;

		if (parent.strumline.player) {
			game.totalPlayed++;
			Rating.recalculate();

			if (count) {
				game.misses++;
				game.score -= noteType != null ? noteType.scoreLoss : 100;

				if (type != 'gf') game.stage.gf.checkComboDrop(game.combo);

				game.combo = 0;
			} else {
				game.score -= 10;
			}

			game.health -= healthLoss;
		}

		game.ui.curStrumline.voices.volume = 0;

		var char = type == 'gf' ? game.stage.gf : parent.strumline.character;
		char.sing(dir, true);
		char.holdTimer = -1;

		FlxG.sound.play(Path.sound('miss' + FlxG.random.int(1, 3)));

		if (prevCombo >= 10 && prevCombo != game.combo) {
			Rating.create();
		}
	}

	function unpressedKey(key:FlxKey):Bool {
		return !Controls.pressedKeys[key];
	}

	override public function kill():Void {
		if (sustain != null) {
			sustain.kill();
			sustain = null;
		}
		super.kill();
	}
}