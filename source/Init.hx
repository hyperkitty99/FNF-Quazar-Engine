package;

import lime.app.Application;

import openfl.events.UncaughtErrorEvent;
import openfl.events.UncaughtErrorEvent.UNCAUGHT_ERROR as ERROR;
import openfl.Lib;

import haxe.CallStack;

class Init extends FlxState {
	override function create():Void {
		Controls.init();
		Settings.load();

		var window = lime.app.Application.current.window;

		switch Data.fullscrenType {
			case "Windowed":
				window.fullscreen = false;
				Util.resizeWindow(Std.parseInt(Data.screenRes.split('x')[0]), Std.parseInt(Data.screenRes.split('x')[1]));

			case "Fullscreen":
				window.fullscreen = true;

			case "Borderless":
				window.fullscreen = false;

				var display = lime.system.System.getDisplay(0);
				Util.resizeWindow(Std.int(display.bounds.width), Std.int(display.bounds.width));
		}

		if (Data.fullscrenType == "Windowed") {
			Util.resizeWindow(Std.parseInt(Data.screenRes.split('x')[0]), Std.parseInt(Data.screenRes.split('x')[1]));
		}


		Lib.current.stage.application.window.onClose.add(Settings.save);
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(ERROR, onError);

		FlxG.fixedTimestep = false;
		FlxG.mouse.useSystemCursor = true;

		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];

		if (FlxG.save.data?.fullscreen) {
			FlxG.fullscreen = FlxG.save.data.fullscreen;
		}

		FlxObject.defaultMoves = false;

		Highscore.load();

		FlxG.switchState(new TitleState());

		super.create();

		if (Constants.VERBOSE) Logger.init();
	}

	function onError(e:UncaughtErrorEvent):Void {
		var errorMessage:String = '';

		for (item in CallStack.exceptionStack(true)) {
			switch item {
				case FilePos(s, file, line, column): errorMessage += '$file: line $line\n';
				default: Sys.println(item);
			}
		}

		Application.current.window.alert(errorMessage += '\n${e.error}', 'Error');
		Sys.println(errorMessage);
		Sys.exit(1);
	}
}