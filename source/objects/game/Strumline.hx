package objects.game;

class Strumline extends FlxSpriteGroup {
	public var noteData:Array<NoteJSON> = [];
	public var nextNote:Int = 0;

	public var strums:Array<StrumNote> = [];
	public var sustainCovers:Array<SustainCover> = [];

	public var notes:FlxTypedSpriteGroup<Note>;
	public var sustains:FlxTypedSpriteGroup<Sustain>;
	public var splashes:FlxTypedSpriteGroup<NoteSplash>;
	public var endSplashes:FlxTypedSpriteGroup<SustainCover>;
	public var sparks:Array<Spark> = [];
	public var sustainLights:Array<SustainLight> = [];

	public var voices:FlxSound;

	public var autoHit:Bool = false;
	public var player:Bool = false;

	public var skin:String = 'default';
	public var skinData:NoteSkinData = new NoteSkinData('default');

	public var character:Character;

	public function new(x:Float, y:Float, camera:FlxCamera, botplay:Bool = false, player:Bool = false):Void {
		super(x, y);

		if (camera != null) this.camera = camera;

		this.player = player;
		autoHit = player ? botplay : true;

		for (i in 0...4) {
			strums.push(new StrumNote(i, this));
			strums[i].x = (skinData.meta.padding * strums[i].scale.x) * i;
			add(strums[i]);
		}

		add(sustains = new FlxTypedSpriteGroup());

		for (i in 0...4) {
			if (skinData.meta.hasSustainCovers) {
				sustainCovers.push(new SustainCover(i));
				sustainCovers[i].loadSkin(skinData);
				add(sustainCovers[i]);
			}

			if (skinData.meta.hasSustainLights) {
				sustainLights.push(new SustainLight(i));
				sustainLights[i].loadSkin(skinData);
				sustainLights[i].origin.y = 0;
				add(sustainLights[i]);
			}

			if (skinData.meta.hasSparks) {
				sparks.push(new Spark(i));
				sparks[i].loadSkin(skinData);
				add(sparks[i]);
			}
		}

		add(notes = new FlxTypedSpriteGroup());
		
		if (skinData.meta.hasNoteSplashes) {
			add(splashes = new FlxTypedSpriteGroup());
		}

		if (skinData.meta.hasSustainCovers) {
			add(endSplashes = new FlxTypedSpriteGroup());
		}
	}

	public function loadSkin(path:String = 'default'):Void {
		skinData.loadSkin(skin = path);

		for (strum in strums) {
			strum.onSkinChange();
		}

		for (note in notes) {
			note.onSkinChange();
		}

		if (skinData.meta.hasNoteSplashes) {
			for (splash in splashes) {
				splash.loadSkin(skinData);
			}
		}

		if (skinData.meta.hasSustainCovers) {
			for (cover in sustainCovers) {
				cover.loadSkin(skinData);
			}

			for (endSplash in endSplashes) {
				endSplash.loadSkin(skinData);
			}
		}

		if (skinData.meta.hasSparks) {
			for (spark in sparks) {
				spark.loadSkin(skinData);
			}
		}

		if (skinData.meta.hasSustainLights) {
			for (sustainLight in sustainLights) {
				sustainLight.loadSkin(skinData);
			}
		}
	}

	override public function update(elapsed:Float):Void {
        super.update(elapsed);

		if (noteData == null || noteData.length == 0) return;

		while (nextNote < noteData.length && noteData[nextNote].time <= lookAheadMS()) {
        	notes.recycle(newNote).setup(noteData[nextNote], this);
			notes.sort(byTime);
        	++nextNote;
        }
    }

	function lookAheadMS():Float {
		var screenHeight:Float = FlxG.height / camera.zoom;
		return game.conductor.time + (screenHeight * Constants.LOOK_AHEAD_FACTOR) / (game.scrollSpeed * Constants.SCROLLSPEED_FACTOR);
	}

	function newNote():Note {
		var note = new Note(this);
		note.camera = camera;
		return note;
	}

	function byTime(Order:Int, Obj1:Note, Obj2:Note):Int {
		return FlxSort.byValues(Order, Obj1.time, Obj2.time);
	}
}