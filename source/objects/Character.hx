package objects;

typedef CharacterData = {animations:Array<CharAnimArray>, image:String, healthbarColor:String, ?singDuration:Float, ?cameraPosition:Array<Float>, ?scale:Float, ?flipX:Bool, ?flipY:Bool, ?antialiasing:Bool}

typedef AnimArray = {name:String, prefix:String, offsets:Array<Float>, ?fps:Int, ?loop:Bool, ?indices:Array<Int>}
typedef GlobalAnimData = {?offsets:Array<Float>, ?fps:Int, ?loop:Bool}

typedef CharAnimArray = AnimArray & {cameraOffsets:Array<Float>, ?image:String}

@:build(macros.AgnosticOffsetMacro.build())
class Character extends FlxSprite {
	public var offsets:Map<String, Array<Float>> = new Map();
	public var cameraOffsets:Map<String, Array<Float>> = new Map();

	public var character:String = 'bf';
	public var singDuration:Float = 4;

	public var cameraPosition:Array<Float> = [0, 0];
	public var cameraOffset:Array<Float> = [0, 0];
	public var healthbarColor:String = '31b0d1';

	public var onAnimPlay:FlxTypedSignal<String -> Void> = new FlxTypedSignal();

	public var altSuffix:String = '';

	public var specialAnim:Bool = false;
	public var stunned:Bool = false;

	public var danceIdle:Bool = false;
	public var player:Bool = false;

	public var sustaining:Bool = false;

	public var iconOffset:Array<Float> = [0, 0];
	public var danceEveryNumBeats:Int = 2;
	public var holdTimer:Float = 0;

	public var ogFlipX:Bool = false;

	public var speed:Float = 1;

	public var _editor:Bool = false;
	public var imageFile:String;

	public var stepLength:Float;

	var danced:Bool = false;

 	public var dropNoteCounts:Array<Int> = [];

	public function new(x:Float = 0, y:Float = 0, character:String, player:Bool = false):Void {
		super(x, y);

		this.player = player;
		this.character = character;

		loadCharacter(character);

    	dropNoteCounts = findDropCounts();
	}

	public function loadCharacter(character:String):Void {
		offsets = [];

		var json:CharacterData = Path.character(character);

		antialiasing = json.antialiasing ?? Data.antialiasing;
		flipX = (json.flipX != player) ?? false;
		flipY = json.flipY ?? false;

		ogFlipX = (json.flipX == true);

		healthbarColor = json.healthbarColor ?? '31b0d1';
		cameraPosition = json.cameraPosition ?? [0, 0];
		singDuration = json.singDuration ?? 4;

		imageFile = json.image;

		frames = Path.multiSparrow(json.image.split(','), 'data/characters/$character');

		for (curAnim in json.animations) {
			if (curAnim.indices != null && curAnim.indices.length > 0) {
				animation.addByIndices(curAnim.name, curAnim.prefix, curAnim.indices, "", curAnim.fps ?? 24, curAnim.loop ?? false);
			} else {
				animation.addByPrefix(curAnim.name, curAnim.prefix, curAnim.fps ?? 24, curAnim.loop ?? false);
			}

			offsets.set(curAnim.name, curAnim.offsets == null ? [0, 0] : curAnim.offsets);
			cameraOffsets.set(curAnim.name, curAnim.cameraOffsets == null ? [0, 0] : curAnim.cameraOffsets);
		}

		scale.set(json.scale ?? 1, json.scale ?? 1);
		updateHitbox();

		danceIdle = (offsets.exists('danceLeft') && offsets.exists('danceRight'));
    	danceEveryNumBeats = danceIdle ? 1 : 2;
		dance();
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (specialAnim && animation.curAnim.finished) {
			specialAnim = false;
			dance();
		}

		if (_editor) return;

		if (animation.curAnim.name.startsWith('sing')) {
			if (holdTimer >= stepLength * 0.001 * singDuration) {
				dance();
			}
			holdTimer += elapsed;
		} else {
			holdTimer = 0;
		}

		if (!animation.curAnim.name.endsWith('-hold') && animation.curAnim.finished) {
			playAnim('${animation.curAnim.name}-hold');
		}
	}

	public function onBeatHit(curBeat:Int):Void {
		if (curBeat % Math.round(danceEveryNumBeats * speed) != 0 || animation.curAnim.name.startsWith('sing')) return;
		dance();
	}

	public function sing(dir:String, miss:Bool = false):Void {
		if (specialAnim || stunned) return;

		playAnim('sing${dir.toUpperCase()}${miss ? 'miss' : ''}', true);
		holdTimer = 0;
	}

	public function dance():Void {
		if (specialAnim || stunned) return;
		playAnim(danceIdle ? (danced = !danced) ? 'danceRight' : 'danceLeft' : 'idle');
	}

	public function playAnim(name:String, force:Bool = false, reverse:Bool = false, frame:Int = 0):Void {
		var curAnim = flipX ? (~/LEFT|RIGHT/g).map(name, swapLeftRight) : name;

		animation.play(curAnim + altSuffix, force, reverse, frame);
		if (offsets.exists(curAnim)) offset.set(offsets[curAnim][0] ?? 0, offsets[curAnim][1] ?? 0);
		if (cameraOffsets.exists(curAnim)) cameraOffset = [cameraOffsets[curAnim][0] ?? 0, cameraOffsets[curAnim][1] ?? 0];

		onAnimPlay.dispatch(animation.curAnim.name);
	}

	function swapLeftRight(r:EReg):String {
    	return r.matched(0) == 'LEFT' ? 'RIGHT' : 'LEFT';
  	}

	function findDropCounts():Array<Int> {
    	var result:Array<Int> = [];

    	for (anim in animation.getNameList()) {
			if (!anim.startsWith('drop')) continue;

        	var dropNum:Null<Int> = Std.parseInt(anim.substring(4));

        	if (dropNum == null) break;
          	result.push(dropNum);
    	}

    	result.sort(sortThingy);

    	return result;
  	}

	public function checkComboDrop(combo:Int):Void {
		var dropAnim:String = null;

    	for (count in dropNoteCounts) {
      		if (combo >= count) {
        		dropAnim = 'drop${count}';
      		}
    	}

    	if (dropAnim == null) return;

      	playAnim(dropAnim, true);
		specialAnim = true;
		holdTimer = 0;
	}

	public function checkCombo(combo:Int):Void {
		if (animation.getByName('combo$combo') == null) return;

		playAnim('combo$combo', true);
		specialAnim = true;
		holdTimer = 0;
	}

	function sortThingy(a:Int, b:Int):Int {
		return a - b;
	}
}