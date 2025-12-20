package states;

import backend.WeekData.SongData;
import backend.WeekData.DiffData;
import substates.StickerSubState;

class FreeplayState extends Scene {
	static var curSelected:Int = 0;
	static var curDifficulty:Int = 1;

	static var lastWeekDifficulties:Map<Int, Int> = [];

	var songs:Array<SongData> = [];

	var songsGrp:Array<AlphabetLock> = [];
    var iconsGrp:Array<HealthIcon> = [];

	var lerpSelected:Float = 0;

	var scoreBG:FlxSprite;
	var diffText:FlxText;
	var scoreText:FlxText;

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	var bg:FlxSprite;
	var colorTween:FlxTween;

	var stickerSubState:StickerSubState;

    public function new(?stickers:StickerSubState = null):Void {
        super();

        if (stickers != null) {
            stickerSubState = stickers;
        }
    }

	override function create():Void {
		if (stickerSubState != null) {
            persistentUpdate = persistentDraw = true;

            openSubState(stickerSubState);
            stickerSubState.degenStickers();
        }

		if (!FlxG.sound.music.playing) {
			FlxG.sound.playMusic(Path.music('freakyMenu'), 0.5);
		}

		PlayState.isStoryMode = false;
		WeekData.reload();

		if (WeekData.weeks.length < 1) {
			if (Constants.VERBOSE) trace('ya got no weeks buddy go back lmaooo');
			Key.onPress(Key.back, onBack);
			return;
		}

		for (i => week in WeekData.weeks) {
			for (song in WeekData.loadedWeeks[week].songs) {
				song.week = i;
				song.displayName = song.displayName == null ? song.name : song.displayName;
				songs.push(song);
			}
		}

		add(bg = UIUtil.background(FlxColor.fromString(songs[curSelected].color)));

		for (i => song in songs) {
            var songName:String = song.displayName == null ? song.name : song.displayName;
			var unknownSong:String = ~/[^ ]/g.replace(songName, '?');

			final text:AlphabetLock = new AlphabetLock(90, 320, songLocked(i) ? unknownSong : songName, songLocked(i));
			text.targetY = i;
			text.visible = text.active = false;
			songsGrp.push(text);
			add(text);

			final icon:HealthIcon = new HealthIcon(song.icon);
			icon.sprTracker = text;
			icon.color = songLocked(i) ? FlxColor.BLACK : FlxColor.WHITE;
			icon.visible = icon.active = false;
			iconsGrp.push(icon);
            add(icon);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0).setFormat(Path.font('vcr.ttf'), 32, FlxColor.WHITE, RIGHT);

		add(scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0x99000000));

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, '', 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		Key.onPress(Key.accept, onAccept);
        Key.onPress(Key.back, onBack);

		Key.onPress(Key.up, changeItem.bind(-1));
		Key.onPress(Key.down, changeItem.bind(1));

		Key.onPress(Key.left, changeDiff.bind(-1));
		Key.onPress(Key.right, changeDiff.bind(1));

		changeItem();

		lerpSelected = curSelected;
    	cullTexts();

		super.create();
	}

	override function update(elapsed:Float):Void {
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
    	cullTexts();

    	super.update(elapsed);

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));

		if (Math.abs(lerpScore - intendedScore) <= 10) {
			lerpScore = intendedScore;
		}

		scoreText.text = 'PERSONAL BEST: $lerpScore'; //TODO: add song's percentage

		positionHighscore();
	}

	function onBack():Void {
		FlxG.sound.play(Path.sound('cancel'), 0.6);
		FlxG.switchState(new MainMenuState());
	}

	function songLocked(i:Int = null):Bool {
		return WeekData.isLocked(WeekData.loadedWeeks.keyForValue(WeekData.getCurrent(songs[i == null ? curSelected : i].week)));
	}

	function onAccept():Void {
		if (songLocked()) {
			FlxG.sound.play(Path.sound('cancel'), 0.6);
			songsGrp[curSelected].triggerLock();
			return;
		}

        PlayState.songs = [songs[curSelected].name];
		PlayState.curSong = PlayState.songs[0];
		PlayState.isStoryMode = false;
		PlayState.curWeek = songs[curSelected].week;
		FlxG.switchState(new PlayState());
	}

	function changeItem(dir:Int = 0):Void {
		if (dir != 0) {
			FlxG.sound.play(Path.sound('scroll'), 0.4);

			lastWeekDifficulties.set(songs[curSelected].week, curDifficulty);
		}

		curSelected = (curSelected + dir + songsGrp.length) % songsGrp.length;

		if (FlxColor.fromString(songs[curSelected].color) != bg.color) {
			if (colorTween != null) colorTween.cancel();
			colorTween = FlxTween.color(bg, 1, bg.color, FlxColor.fromString(songs[curSelected].color));
		}

		curDifficulty = lastWeekDifficulties.exists(songs[curSelected].week) ? lastWeekDifficulties[songs[curSelected].week] : 0;

		changeDiff();
	}

	function changeDiff(dir:Int = 0):Void {
		if (songLocked()) {
			diffText.text = '';
			intendedScore = 0 ;
			return;
		}

		var difficulties:Array<DiffData> = WeekData.getCurrent(songs[curSelected].week).difficulties;

		if (songs[curSelected].diff != null) {
			difficulties = songs[curSelected].diff;
		}

		curDifficulty = (curDifficulty + dir + difficulties.length) % difficulties.length;

		lastWeekDifficulties.set(songs[curSelected].week, curDifficulty);

		PlayState.difficulty = difficulties[curDifficulty].name;
		diffText.text = difficulties[curDifficulty].displayName.toUpperCase();

		intendedScore = Highscore.getScore(songs[curSelected].name, PlayState.difficulty);
	}

	function positionHighscore():Void {
		diffText.x = scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x * 0.5);
	}

	final _drawDistance:Int = 4;
	function cullTexts():Void { //some people would call this borrowing, i call this referencing
		final min:Int = Util.boundInt(lerpSelected - _drawDistance, 0, songs.length);
		final max:Int = Util.boundInt(lerpSelected + _drawDistance, 0, songs.length);

    	for (i => song in songsGrp) {
    	    song.visible = song.active = iconsGrp[i].visible = iconsGrp[i].active = i >= min && i < max;

			if (!song.visible) continue;

    	    song.x = ((song.targetY - lerpSelected) * song.distancePerItem.x) + song.startPos.x;
    	    song.y = ((song.targetY - lerpSelected) * 1.3 * song.distancePerItem.y) + song.startPos.y;

			song.alpha = iconsGrp[i].alpha = song.targetY == curSelected ? 1 : 0.6;
    	}
	}
}