package backend;

import substates.GameOverSubState;
import substates.PauseSubState;

class PlayerControls {
	public static var safeMS:Float = (Data.safeFrames / 60) * 250;

	public static function init():Void {
		Key.onPress(Key.reset, onReset);
		Key.onPress(Key.debug, onChartEditor);
		Key.onPress(Key.pause, onPause);

		for (i => bind in Constants.NOTEBIND_NAMES) {
			Key.onPress(Data.keybinds[bind], onPress.bind(i));
			Key.onRelease(Data.keybinds[bind], onRelease.bind(i));
		}
	}

	static function onChartEditor():Void {
		FlxG.switchState(new ChartEditor(game.chart));
	}

	static function onPause():Void {
		if (game.ended) return;
		game.openSubState(new PauseSubState());
	}

	static function onReset():Void {
		if (game.ended || !Data.reset) return;
		game.openSubState(new GameOverSubState(game.ui.curStrumline.character));
	}

	static function onRelease(id:Int):Void {
		if (game.ended || PlayState.botplay) return;
		game.ui.curStrumline.strums[id].resetAnim();
	}

	static function onPress(id:Int):Void {
		if (game.ended || PlayState.botplay) return;

		for (note in game.ui.curStrumline.notes.members) {
			if (note?.exists && note.alive && note.data % Constants.NOTEBIND_NAMES.length == id && note.hittable) {
				var diff:Float = Math.abs(game.conductor.time - note.time);

				if (diff <= Constants.SHIT_WINDOW + safeMS) {
					note.hit();
					note.judge(diff, id);
					return;
				}
			}
		}

		if (!Data.ghostTapping) {
			game.ui.curStrumline.voices.volume = 0;

			game.totalPlayed++;
			Rating.recalculate();

			game.score -= 10;
			game.health -= 0.025;

			var char = game.ui.curStrumline.character;
			char.sing(Constants.DIRECTION[id % Constants.DIRECTION.length], true);
			char.holdTimer = -1;

			FlxG.sound.play(Path.sound('miss' + FlxG.random.int(1, 3)));
		}

		game.ui.curStrumline.strums[id].press();
	}
}