package tools;

import flixel.system.scaleModes.RatioScaleMode;
import flixel.system.scaleModes.StageSizeScaleMode;
import flixel.util.FlxAxes;
import openfl.display.BlendMode;

class Util {
    public static function getEase(ease:String):Float -> Float {
		return switch ease.toLowerCase().trim() {
			case 'backin': FlxEase.backIn;
			case 'backinout': FlxEase.backInOut;
			case 'backout': FlxEase.backOut;
			case 'bouncein': FlxEase.bounceIn;
			case 'bounceinout': FlxEase.bounceInOut;
			case 'bounceout': FlxEase.bounceOut;
			case 'circin': FlxEase.circIn;
			case 'circinout': FlxEase.circInOut;
			case 'circout': FlxEase.circOut;
			case 'cubein': FlxEase.cubeIn;
			case 'cubeinout': FlxEase.cubeInOut;
			case 'cubeout': FlxEase.cubeOut;
			case 'elasticin': FlxEase.elasticIn;
			case 'elasticinout': FlxEase.elasticInOut;
			case 'elasticout': FlxEase.elasticOut;
			case 'expoin': FlxEase.expoIn;
			case 'expoinout': FlxEase.expoInOut;
			case 'expoout': FlxEase.expoOut;
			case 'quadin': FlxEase.quadIn;
			case 'quadinout': FlxEase.quadInOut;
			case 'quadout': FlxEase.quadOut;
			case 'quartin': FlxEase.quartIn;
			case 'quartinout': FlxEase.quartInOut;
			case 'quartout': FlxEase.quartOut;
			case 'quintin': FlxEase.quintIn;
			case 'quintinout': FlxEase.quintInOut;
			case 'quintout': FlxEase.quintOut;
			case 'sinein': FlxEase.sineIn;
			case 'sineinout': FlxEase.sineInOut;
			case 'sineout': FlxEase.sineOut;
			case 'smoothstepin': FlxEase.smoothStepIn;
			case 'smoothstepinout': FlxEase.smoothStepInOut;
			case 'smoothstepout': FlxEase.smoothStepOut;
			case 'smootherstepin': FlxEase.smootherStepIn;
			case 'smootherstepinout': FlxEase.smootherStepInOut;
			case 'smootherstepout': FlxEase.smootherStepOut;
            default: FlxEase.linear;
		}
    }

    public static function getTweenType(type:String):FlxTweenType {
		return switch type.toLowerCase().trim() {
			case 'backward': FlxTweenType.BACKWARD;
			case 'looping' | 'loop': FlxTweenType.LOOPING;
			case 'persist': FlxTweenType.PERSIST;
			case 'pingpong': FlxTweenType.PINGPONG;
            default: FlxTweenType.ONESHOT;
		}
	}

    public static function getblendMode(blend:String):BlendMode {
		return switch blend.toLowerCase().trim() {
			case 'add': ADD;
			case 'alpha': ALPHA;
			case 'darken': DARKEN;
			case 'difference': DIFFERENCE;
			case 'erase': ERASE;
			case 'hardlight': HARDLIGHT;
			case 'invert': INVERT;
			case 'layer': LAYER;
			case 'lighten': LIGHTEN;
			case 'multiply': MULTIPLY;
			case 'overlay': OVERLAY;
			case 'screen': SCREEN;
			case 'shader': SHADER;
			case 'subtract': SUBTRACT;
            default: NORMAL;
		}
	}

	public static function getCharacter(character:String):Character {
		if (game == null) {
			if (Constants.VERBOSE) trace('Game is not initialized yet');
			return null;
		}

		return switch character {
            case 'dad': game.stage.dad;
            case 'gf': game.stage.gf;
            case 'bf': game.stage.bf;
            default: null;
        }
	}

	public static function getCharacterTarget(character:Character):String {
		if (game == null) {
			if (Constants.VERBOSE) trace('Game is not initialized yet');
			return null;
		}

		return switch character {
			case(_ == game.stage.gf) => true: 'gf';
			case(_ == game.stage.dad) => true: 'dad';
			case(_ == game.stage.bf) => true: 'bf';
			default: 'invalid';
		};
	}

	public static function getCamera(camera:String):FlxCamera {
		if (game == null) {
			if (Constants.VERBOSE) trace('Game is not initialized yet');
			return null;
		}

		return switch camera {
            case 'camGame': game.camera;
            case 'camHUD': game.camHUD;
            case 'camOther': game.camOther;
            default: null;
        }
	}

	public static inline function bound(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}

	public static inline function boundInt(value:Float, min:Float, max:Float):Int {
		return Std.int(bound(value, min, max));
	}

	public static inline function lerp(base:Float, target:Float, ratio:Float):Float {
		return target + (base - target) * Math.exp(-FlxG.elapsed * ratio);
	}

	public static inline function coolLerp(base:Float, target:Float, ratio:Float):Float {
		return base + (ratio * (FlxG.elapsed / (1 / 60))) * (target - base);
	}

	public static inline function lerpColor(Color1:FlxColor, Color2:FlxColor, Factor:Float = 0.5):FlxColor {
		return FlxColor.interpolate(Color1, Color2, Factor);
	}

	public static inline function capitalize(text:String):String {
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();
	}

	public static inline function sortByZIndex(order:Int, obj1:FlxBasic, obj2:FlxBasic):Int {
		return FlxSort.byValues(order, obj1.zIndex, obj2.zIndex);
	}

	public static inline function sortByEventTime(a:EventJSON, b:EventJSON):Int {
		return (a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
	}

	public static inline function sortByNoteTime(a:NoteJSON, b:NoteJSON):Int {
		return (a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
	}

	public static function displayKey(key:FlxKey):String {
		return Constants.FORMATTED_KEYS.exists(key) ? Constants.FORMATTED_KEYS[key] : getKey(key);
	}

	public static function getKey(key:String):String {
		return key == 'null' ? '--' : key.contains('_') ? Util.capitalize(key).replace('_', ' ') : Util.capitalize(key);
	}

	public static function resizeWindow(width:Int, height:Int, ?x:Int, ?y:Int):Void {
		var display = lime.system.System.getDisplay(0);
		lime.app.Application.current.window.x = x != null ? x : Std.int((display.bounds.width - width) * 0.5);
		lime.app.Application.current.window.y = y != null ? y : Std.int((display.bounds.height - height) * 0.5);

		FlxG.resizeGame(width, height);
		FlxG.resizeWindow(width, height);

		// if (Math.abs((width / height) - 1.333) < 0.05) {
		// 	FlxG.scaleMode = new StageSizeScaleMode();
		// } else {
		// 	FlxG.scaleMode = new RatioScaleMode();
		// }
	}
}

class ImplementableUtil {
	public static function screenCenterIn<T:FlxObject>(object:T, axes:FlxAxes = XY, width:Float = null, height:Float = null):T {
		if (axes.x)
			object.x = (width == null ? FlxG.width : width - object.width) * 0.5;

		if (axes.y)
			object.y = (height == null ? FlxG.height : height - object.height) * 0.5;

		return object;
	}

	public static function keyForValue<T:Map<K, V>, K, V>(map:T, value:V):Null<K> {
    	for (key => val in map) {
			if (val != value) continue;
        	return key;
    	}

    	return null;
	}

	public static function getOverlapped<T:FlxBasic>(group:FlxTypedGroup<T>, filter:T -> Bool):Null<T> {
    	if (!FlxG.mouse.overlaps(group)) return null;
    	for (item in group.members) {
        	if (FlxG.mouse.overlaps(item) && filter(item)) {
        	    return item;
        	}
    	}
    	return null;
	}
}

class UIUtil {
    public static function addHeader(name:String, curY:Float, align:FlxTextAlign = LEFT):Void {
        switch align {
            case CENTER:
                final title = new Alphabet(90, curY, name, 0.8, true);
                title.screenCenter(X);
                FlxG.state.add(title);
                
                FlxG.state.add(new FlxSprite(90, title.y + 20).makeGraphic(Std.int(title.x) - 107, 4, FlxColor.BLACK));
                FlxG.state.add(new FlxSprite(Std.int(title.x + title.width + 19), title.y + 20).makeGraphic(Std.int(1190 - (title.x + title.width + 18)), 4, FlxColor.BLACK));
            case LEFT, JUSTIFY:
                final title = new Alphabet(90, curY, name, 0.8, true);
                FlxG.state.add(title);
                
                FlxG.state.add(new FlxSprite(Std.int(109 + title.width), curY + 20).makeGraphic(Std.int(1190 - (108 + title.width)), 4, FlxColor.BLACK));
            case RIGHT:
                final title = new Alphabet(90, curY, name, 0.8, true);
                title.x = Std.int(FlxG.width - 90 - title.width);
                FlxG.state.add(title);

                FlxG.state.add(new FlxSprite(90, title.y + 20).makeGraphic(Std.int(title.x - 107), 4, FlxColor.BLACK));
        }
    }

    public static function background(?color:Int):FlxSprite {
        final bg:FlxSprite = new FlxSprite(Path.image('menuDesat'));
		bg.color = color;
		bg.scrollFactor.set();
        return bg;
    }

    public static function playCancel(volume:Float = 0.6):Void {
        FlxG.sound.play(Path.sound('cancel'), volume);
    }
}