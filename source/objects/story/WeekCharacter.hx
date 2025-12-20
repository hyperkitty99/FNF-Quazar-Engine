package objects.story;

import objects.Character.AnimArray;
import haxe.Json;

typedef WeekCharacterData = {
    var image:String;
    @:optional var scale:Float;
    @:optional var antialiasing:Bool;
    @:optional var danceEvery:Float;
    @:optional var offsets:Array<Float>;
    @:optional var idleAnim:AnimArray;
    @:optional var danceLeft:AnimArray;
    @:optional var danceRight:AnimArray;
    @:optional var confirmAnim:AnimArray;
}

class WeekCharacter extends FlxSprite {
    public var offsets:Map<String, Array<Float>> = new Map();
    public var globalOffset:Array<Float> = [0, 0];
    public var character:String;
    public var danceIdle:Bool = false;
    public var danceEveryNumBeats:Float = 1;
    var danced:Bool = false;

    public function new(x:Float, y:Float, character:String) {
        super(x, y);
        changeCharacter(character);
    }

    public function changeCharacter(?newCharacter:String) {
        offsets = [];

        final character:String = newCharacter != null ? newCharacter : '';
        if (this.character == character) return;
    
        this.character = character;

        if (character == '') {
            visible = false;
            return;
        }

        visible = true;
    
        try {
            var path:String = 'assets/images/storymenu/characters/$character.json';
    
            if (!FileSystem.exists(path)) {
                path = 'assets/images/storymenu/characters/bf.json';
            }

            var data:WeekCharacterData = Json.parse(File.getContent(path));

            frames = Path.sparrow('storymenu/characters/${data.image}');
    
            //im sorry but i dont think there will be any other animations that you could use in story mode im so sorry
            setupAnimation('idle', data.idleAnim);
            setupAnimation('danceLeft', data.danceLeft);
            setupAnimation('danceRight', data.danceRight);
            setupAnimation('confirm', data.confirmAnim);

            if (data.scale != null) {
                scale.set(data.scale, data.scale);
                updateHitbox();
            }

            if (data.offsets != null) {
                globalOffset = data.offsets;
            }

            if (data.danceEvery != null) {
                danceEveryNumBeats = data.danceEvery;
            }

            antialiasing = data.antialiasing ?? Data.antialiasing;

            danceIdle = data.danceLeft != null && data.danceRight != null;
            dance();

        } catch (e:Dynamic) {
            if (Constants.VERBOSE) trace('Failed to load character "$character": $e');
            visible = false;
        }
    }

    function setupAnimation(name:String, animData:AnimArray):Void {
        if (animData == null) return;

        if (animData.indices != null && animData.indices.length > 0) {
			animation.addByIndices(name, animData.name, animData.indices, '', animData.fps, false);
		} else {
            animation.addByPrefix(name, animData.name, animData.fps, false);
		}

        if (animData.offsets != null) {
            offsets.set(name, [animData.offsets[0] ?? 0, animData.offsets[1] ?? 0]);
        }
    }

    public function dance():Void {
		playAnim(danceIdle ? (danced = !danced) ? 'danceRight' : 'danceLeft' : 'idle');
	}

    public function onBeatHit(curBeat:Int):Void {
        if (curBeat % Math.round(danceEveryNumBeats) != 0 || animation.curAnim == null || animation.curAnim.name.startsWith('confirm')) return;
		dance();
    }

	public function playAnim(name:String, force:Bool = false, reverse:Bool = false, frame:Int = 0):Void {
		animation.play(name, force, reverse, frame);
		if (offsets.exists(name)) {
            offset.set((offsets[name][0] ?? 0) + globalOffset[0], (offsets[name][1] ?? 0) + globalOffset[1]);
        } else {
            offset.set(globalOffset[0], globalOffset[1]);
        }
	}
}