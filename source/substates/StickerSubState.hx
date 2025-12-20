package substates;

import flixel.FlxState;
import flixel.FlxSubState;

//this class is horrible
//a lot of shit is horrible
//god i wanna remake this engine
class StickerSubState extends FlxSubState {
    public var grpStickers:FlxTypedGroup<StickerSprite>;
    
    var targetState:StickerSubState -> FlxState;
    var switchingState:Bool = false;

    public static var jsonToLoad:String = 'default';
    public static var json:StickerJSON;

    public static function preload(song:String, character:String):Void {
        if (Path.json('data/stickerpacks/bonus-$song') != null) {
            jsonToLoad = 'bonus-$song';
        } else if (Path.json('data/stickerpacks/standard-$character') != null) {
            jsonToLoad = 'standard-$character';
        } else {
            jsonToLoad = 'default';
        }
    }

    public function new(?oldStickers:Array<StickerSprite>, ?targetState:StickerSubState -> FlxState):Void {
        super();

        json = Path.parseJSON(Path.json('data/stickerpacks/$jsonToLoad'));

        this.targetState = (targetState == null) ? ((sticker) -> new MainMenuState()) : targetState;

        add(grpStickers = new FlxTypedGroup());
        grpStickers.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

        if (oldStickers != null) {
            for (sticker in oldStickers) {
                grpStickers.add(sticker);
            }

            degenStickers();
        } else {
            regenStickers();
        }
    }

    function regenStickers():Void {
        if (grpStickers.members.length > 0) {
            grpStickers.clear();
        }

        var xPos:Float = -100;
        var yPos:Float = -100;
        
        while (xPos <= FlxG.width) {
            var sticky:StickerSprite = new StickerSprite('sticker-sets/${FlxG.random.getObject(json.stickers)}');
            sticky.visible = false;
            sticky.setPosition(xPos, yPos);

            xPos += sticky.frameWidth * 0.5;

            if (xPos >= FlxG.width && yPos <= FlxG.height) {
                xPos = -100;
                yPos += FlxG.random.float(70, 120);
            }

            sticky.angle = FlxG.random.int(-60, 70);
            grpStickers.add(sticky);
        }

        FlxG.random.shuffle(grpStickers.members);

        for (i => sticker in grpStickers.members) {
            sticker.timing = FlxMath.remapToRange(i, 0, grpStickers.members.length, 0, 0.9);

            FlxTimer.wait(sticker.timing, () -> {
                if (grpStickers == null) return;
                sticker.visible = true;

                FlxG.sound.play(Path.sound('stickersounds/${FlxG.random.getObject(Constants.CLICK_SOUNDS)}'));

                var frameTimer:Int = FlxG.random.int(0, 2);

                if (i == grpStickers.members.length - 1) {
                    frameTimer = 2;
                }

            	FlxTimer.wait((1 / 24) * frameTimer, () -> {
                    if (sticker == null) return;

                    sticker.scale.x = sticker.scale.y = FlxG.random.float(0.97, 1.02);

                    if (i == grpStickers.members.length - 1) {
                        switchingState = skipNextTransIn = skipNextTransOut = true;
                        PlayState.resetProperties();
                        FlxG.switchState(targetState.bind(this));
                    }
                });
            });
        }

        grpStickers.sort((ord, a, b) -> {
            return FlxSort.byValues(ord, a.timing, b.timing);
        });

        if (grpStickers.members.length > 0) {
            var lastOne = grpStickers.members[grpStickers.members.length - 1];
            lastOne.updateHitbox();
            lastOne.angle = 0;
            lastOne.screenCenter();
        }
    }

    public function degenStickers():Void {
        grpStickers.cameras = FlxG.cameras.list;

        if (grpStickers.members == null || grpStickers.members.length == 0) {
            switchingState = false;
            close();
            return;
        }

        for (i => sticker in grpStickers.members) {
            FlxTimer.wait(sticker.timing, () -> {
                sticker.visible = false;

                FlxG.sound.play(Path.sound('stickersounds/${FlxG.random.getObject(Constants.CLICK_SOUNDS)}'));

                if (grpStickers == null || i == grpStickers.members.length - 1) {
                    switchingState = false;
                    close();
                }
            });
        }
    }

    override public function close():Void {
        if (switchingState) return;
        super.close();
    }

    override public function destroy():Void {
        if (switchingState) return;
        super.destroy();
    }
}

class StickerSprite extends FlxSprite {
    public var timing:Float = 0;

    public function new(sticker:String):Void {
        super(0, 0, Path.image(sticker));
    }
}

typedef StickerJSON = {
    name:String,
    artist:String,
    stickers:Array<String>
}