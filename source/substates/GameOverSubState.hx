package substates;

class GameOverSubState extends SubScene {
    var isEnding:Bool = false;
    var isExiting:Bool = false;
    var focusCamera:Bool = false;
    
    var character:Character;

    var deathMusic:FlxSound;

    public function new(character:Character = null):Void {
        super();
        this.character = character;
    }

    override function create():Void {
        PlayState.blueballs++;

        bgColor = FlxColor.BLACK;
		game.persistentDraw = false;

		FlxG.sound.list.add(deathMusic = new FlxSound().loadEmbedded(Path.music('deathLoop'), true, true));
        deathMusic.volume = 1;

        add(character = new Character(character.x, character.y, character.character, character.player));
        character.playAnim('firstDeath');

        FlxG.sound.play(Path.sound('firstDeath'));

        super.create();

        Key.onPress(Key.accept, onAccept);
        Key.onPress(Key.back, onBack);
    }

    function onAccept():Void {
        if (isEnding || isExiting) return;
		isEnding = true;

		character.playAnim('deathConfirm', true);
		deathMusic?.stop();
		FlxG.sound.play(Path.sound('deathConfirm'));

        skipNextTransIn = true;
        FlxTimer.wait(0.7, FlxG.camera.fade.bind(FlxColor.BLACK, 2, false, FlxG.resetState));
	}

    function onBack():Void {
        if (isExiting) return;

		isExiting = true;
        skipNextTransIn = false;

        deathMusic?.stop();

		StickerSubState.preload(PlayState.curSong, character.character);
		
        if (PlayState.isStoryMode) {
			openSubState(new StickerSubState(null, (sticker) -> new StoryMenuState(sticker)));
		} else {
			openSubState(new StickerSubState(null, (sticker) -> new FreeplayState(sticker)));
		}
    }

    function moveCamera():Void {
        game.camFollow.setPosition(character.getMidpoint().x + character.cameraOffset[0], character.getMidpoint().y + character.cameraOffset[1]);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if (character.animation.curAnim.curFrame == 0 && character.animation.curAnim.name != 'firstDeath') {
            moveCamera();
        }

        if (character.animation.curAnim.finished && character.animation.curAnim.name == 'firstDeath') {
            character.playAnim('deathLoop', true);
            if (!isEnding || !isExiting) deathMusic.play(true);
        }

        if (character.animation.curAnim.curFrame < 12 || focusCamera) return;

        focusCamera = true;
        moveCamera();
        FlxG.camera.followLerp = 0.6;
    }

    override function destroy():Void {
        super.destroy();
        deathMusic.destroy();
    }
}