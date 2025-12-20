package states;

import objects.story.WeekDifficulty;
import objects.story.WeekCharacter;
import objects.story.WeekTitle;
import substates.StickerSubState;

class StoryMenuState extends MusicScene {
    static var curDifficulty:Int = 1;
    static var curWeek:Int = 0;

    var scoreText:FlxText;
    var weekText:FlxText;

    var weekTitles:Array<WeekTitle> = [];
    var characters:Array<WeekCharacter> = [];

    var difficultySprite:WeekDifficulty;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

    var tracks:FlxText;

    var lerpScore:Int = 0;
	var intendedScore:Int = 0;

    var songTimer:FlxTimer = new FlxTimer();

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
        } else {
            Path.clearStoredMemory();
        }

        if (!FlxG.sound.music.playing) {
			FlxG.sound.playMusic(Path.music('freakyMenu'), 0.5);
		}

        conductor.bpm = TitleState.metadata.bpm;

        PlayState.isStoryMode = true;
		WeekData.reload();

        for (i => week in WeekData.weeks) {
            weekTitles.push(new WeekTitle(0, (i - curWeek) * 110 + 480, WeekData.getCurrent(i).titleImage, WeekData.isLocked(week)));
            add(weekTitles[i]);
		}

        add(new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, 0xFFF9CF51));
		add(new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK));

        for (i in 0...3) {
            characters.push(new WeekCharacter((FlxG.width * 0.25) * (i + 1) - 150, 70, WeekData.getCurrent(curWeek).characters[i]));
			add(characters[i]);
		}

        add(scoreText = new FlxText(10, 10, FlxG.width, 'LEVEL SCORE: 0').setFormat(Path.font('vcr.ttf'), 32));
		add(weekText = new FlxText(10, 10, 0).setFormat(Path.font('vcr.ttf'), 32, 0xFFB2B2B2, RIGHT));
        add(tracks = new FlxText(FlxG.width * 0.05, 500, 0, 'TRACKS\n\n').setFormat(Path.font('vcr.ttf'), 32, 0xFFe55777, CENTER));

        add(leftArrow = new FlxSprite(870, 480));
		leftArrow.frames = Path.sparrow('storymenu/ui');
		leftArrow.animation.addByPrefix('idle', 'leftIdle');
		leftArrow.animation.addByPrefix('confirm', 'leftConfirm');
		leftArrow.animation.play('idle');

		add(difficultySprite = new WeekDifficulty(0, leftArrow.y));

		add(rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y));
		rightArrow.frames = Path.sparrow('storymenu/ui');
		rightArrow.animation.addByPrefix('idle', 'rightIdle');
		rightArrow.animation.addByPrefix('confirm', 'rightConfirm');
		rightArrow.animation.play('idle');

        Key.onPress(Key.accept, onAccept);
        Key.onPress(Key.back, onBack);

        Key.onPress(Key.up, onItemChange.bind(-1));
        Key.onPress(Key.down, onItemChange.bind(1));

        Key.onPress(Key.left, changeDiff.bind(-1));
		Key.onPress(Key.right, changeDiff.bind(1));

        Key.onRelease(Key.left, releaseArrows.bind(-1));
		Key.onRelease(Key.right, releaseArrows.bind(1));

        onItemChange();

        super.create();

        Path.clearUnusedMemory();
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));

		if (Math.abs(lerpScore - intendedScore) <= 10) {
			lerpScore = intendedScore;
		}

		scoreText.text = 'LEVEL SCORE: $lerpScore';
    }

    override function onBeat():Void {
        super.onBeat();

        for (char in characters) {
            char.onBeatHit(curBeat);
		}
    }

    function onAccept():Void {
        weekTitles[curWeek].selected = true;

        if (WeekData.isLocked(WeekData.weeks[curWeek])) {
            FlxG.sound.play(Path.sound('cancel'), 0.6);
            return;
        }

        Controls.block = true;

        FlxG.sound.play(Path.sound('confirm'), 0.7);
        characters[1].playAnim('confirm', true);

		PlayState.songs = [for (song in WeekData.getCurrent(curWeek).songs) song.name];
        PlayState.curSong = PlayState.songs[0];
		PlayState.isStoryMode = true;
        PlayState.curWeek = curWeek;

		PlayState.weekScore = 0;

        songTimer.start(1, startSong);
    }

    function onBack():Void {
		FlxG.sound.play(Path.sound('cancel'), 0.6);
		FlxG.switchState(new MainMenuState());
	}

    function releaseArrows(dir:Int = 0):Void {
        (dir > 0 ? rightArrow : leftArrow).animation.play('idle');
    }

    function startSong(_:FlxTimer):Void {
        FlxG.switchState(new PlayState());
    }

    function onItemChange(dir:Int = 0):Void {
        if (dir != 0) {
			FlxG.sound.play(Path.sound('scroll'), 0.4);
		}

		curWeek = (curWeek + dir + weekTitles.length) % weekTitles.length;

        for (i => week in weekTitles) {
            week.targetY = (i - curWeek) * 110 + 480;
            week.alpha = i == curWeek ? 1 : 0.6;
        }

		changeDiff();

        tracks.text = 'TRACKS\n\n';

        var week = WeekData.getCurrent(curWeek);

        weekText.text = week.desc.toUpperCase();
        weekText.x = FlxG.width - (weekText.width + 10);

		for (song in week.songs) {
            var songName:String = song.displayName == null ? song.name : song.displayName;
            var unknownSong:String = ~/[^ ]/g.replace(songName, '?');

			tracks.text += '${WeekData.isLocked(WeekData.weeks[curWeek]) ? unknownSong : songName}\n';
		}

        for (i => char in characters) {
			char.changeCharacter(week.characters[i]);
		}

		tracks.screenCenter(X);
		tracks.x -= FlxG.width * 0.35;
    }

    function changeDiff(dir:Int = 0):Void {
        if (dir != 0) {
            (dir > 0 ? rightArrow : leftArrow).animation.play('confirm');
        }

        difficultySprite.visible = leftArrow.visible = rightArrow.visible = !WeekData.isLocked(WeekData.weeks[curWeek]);

        if (!difficultySprite.visible) {
            intendedScore = 0;
            return;
        }

        var week = WeekData.getCurrent(curWeek);

		curDifficulty = (curDifficulty + dir + week.difficulties.length) % week.difficulties.length;
		PlayState.difficulty = week.difficulties[curDifficulty].name;

        intendedScore = Highscore.getWeekScore(WeekData.weeks[curWeek], PlayState.difficulty);

        difficultySprite.updateGraphic(leftArrow.x, leftArrow.y, PlayState.difficulty);
	}
}