package;

import openfl.geom.Rectangle;
import openfl.utils.Assets;
import flixel.system.ui.FlxSoundTray;
import openfl.display.Bitmap;

class SoundTray extends FlxSoundTray {
    var lerpYPos:Float = 0;
    var alphaTarget:Float = 0;

    var volumeMaxSound:String;

    public function new():Void {
        super();

        removeChildren();
        _bars = [];

        addChild(addBitmap('volumebox'));

        y = -height;
        visible = false;

        _bars.push(addBitmap('bars', 9, 5));
        addChild(_bars[0]);

        screenCenter();

        volumeUpSound = 'Volup';
        volumeDownSound = 'Voldown';
        volumeMaxSound = 'VolMAX';

        if (FlxG.sound.muted || FlxG.sound.volume == 0) {
            moveTrayMakeVisible();
        }
    }

    function addBitmap(path:String, x:Float = 0, y:Float = 0, alpha:Float = 1):Bitmap {
        var bitmap:Bitmap = new Bitmap(Assets.getBitmapData('assets/images/soundtray/$path.png'));
        bitmap.x = x;
        bitmap.y = y;
        bitmap.alpha = alpha;
        bitmap.scaleX = bitmap.scaleY = 0.3;
        bitmap.smoothing = true;
        return bitmap;
    }

    override public function update(ms:Float):Void {
        y = Util.coolLerp(y, lerpYPos, 0.1);
        alpha = Util.coolLerp(alpha, alphaTarget, 0.25);

        if (!FlxG.sound.muted && FlxG.sound.volume >= 0.01) {
            if (_timer > 0) {
                _timer -= ms * 0.001;
            } else if (y >= -height) {
                lerpYPos = -height - 10;
                alphaTarget = 0;
            }

            if (y <= -height) {
                visible = active = false;
            }
        } else if (!visible) {
            moveTrayMakeVisible();
        }
    }

    override public function showIncrement():Void {
		show(true);
	}

	override public function showDecrement():Void {
		show(false);
	}

    override public function show(up:Bool = false):Void {
        moveTrayMakeVisible(up);

        #if FLX_SAVE
        if (!FlxG.save.isBound) return;

        FlxG.save.data.mute = FlxG.sound.muted;
        FlxG.save.data.volume = FlxG.sound.volume;
        FlxG.save.flush();
        #end
    }

    function moveTrayMakeVisible(up:Bool = false):Void {
        _timer = alphaTarget = 1;
        lerpYPos = 10;
        visible = active = true;

        _bars[0].scrollRect = new Rectangle(0, 0, Constants.SOUND_TRAY_CLIP_VALUES[getGlobalVolume(up) - 1], _bars[0].bitmapData.height);
    }

    function getGlobalVolume(up:Bool = false):Int {
        var globalVolume:Int = FlxG.sound.muted || FlxG.sound.volume == 0 ? 0 : Math.round(FlxG.sound.volume * 10);

        var sound:String = globalVolume == 10 ? volumeMaxSound : up ? volumeUpSound : volumeDownSound;
        FlxG.sound.load(Path.sound(sound)).play().volume = 0.3;

        return globalVolume;
    }
}