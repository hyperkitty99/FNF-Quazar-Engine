package states;

import substates.GameOverSubState;
import flixel.FlxSubState;

class PlayState extends MusicScene {
	public static var game:PlayState;
	public static var songs:Array<String> = [];
	public static var curSong:String = PlayState.songs[0];

	public static var difficulty:String = 'normal';
	public static var isStoryMode:Bool = false;
	public static var curWeek:Int = 0;

	public static var chartingMode:Bool = false;
	public static var skipCountdown:Bool = false;

	public static var botplay:Bool = false;
	public static var practiceMode:Bool = false;

	public static var weekScore:Int = 0;
	public static var blueballs:Int = 0;

	public static var uiSkin:String = 'default';

	public var stage:BaseStage;
	public var ui:UI;

	public var camHUD:FlxCamera;
	public var camOther:FlxCamera;
	public var camFollow:FlxObject;
	public static var lastCamFollow:FlxObject;

	public var cameraZoom:Float = 1;
	public var cameraSpeed:Float = 1;

	public var disableCamera:Bool = false;
	public var target:String;

	public var health(default, set):Float = 0.5;

	public var score:Int = 0;
	public var accuracy:Float = 0;
	public var misses:Int = 0;
	public var combo:Int = 0;

	public var ratings:Array<Rating> = [
		Rating.add('Awful', 0.2),
		Rating.add('Shit', 0.4),
		Rating.add('Bad', 0.5),
		Rating.add('Mid', 0.6),
		Rating.add('Nice', 0.7),
		Rating.add('Good', 0.8),
		Rating.add('Great', 0.9),
		Rating.add('Sick', 1),
		Rating.add('Perfect', 1)
	];

	public var totalPlayed:Int = 0;
	public var totalHit:Float;
	public var curRating:String = '?';
	public var percent:Float;

	public var chart:Chart;
    public var events:Array<EventJSON> = [];

    public var inst:FlxSound;
    public var voices:FlxSound;
    public var opponentVoices:FlxSound;

    public var scrollSpeed:Float = 1;

    public var paused:Bool = false;
	public var started:Bool = false;
	public var ended:Bool = false;

    public var canResync:Bool = true;

	public var unpauseSustainWindow:Float = 0;

	public static function resetProperties():Void {
		curSong = '';
		isStoryMode = chartingMode = skipCountdown = botplay = practiceMode = false;
		blueballs = 0;
	}

    override public function create():Void {
		game = this;

		Path.clearStoredMemory();
		Path.preloadGameAssets(PlayState.uiSkin, PlayState.curSong);

		FlxG.cameras.add(camHUD = new FlxCamera(), false).bgColor = 0x00000000;
		FlxG.cameras.add(camOther = new FlxCamera(), false).bgColor = 0x00000000;

		FlxG.sound.music.stop();

		loadSong(PlayState.curSong, PlayState.difficulty);
		conductor.bpm = chart.bpm;

		add(stage = Stage.get(chart.stage, chart.player1, chart.player2, chart.player3));
		add(ui = new UI(camHUD));

		initCamera();
		PlayerControls.init();

		super.create();

		Path.clearUnusedMemory();

		stage.createPost();
    }

	public function loadSong(curSong:String, difficulty:String):Void {
        chart = PlayState.chartingMode ? ChartEditor.chart : Path.chart(curSong, difficulty);
        events = chart.events != null ? chart.events.copy() : [];

        scrollSpeed = chart.speed ?? 1;

        inst = Path.song('Inst', curSong);
        voices = Path.song('Voices-Player', curSong);
        opponentVoices = Path.song('Voices-Opponent', curSong);

        for (val in [inst, voices, opponentVoices]) {
            val?.play();
            val?.stop();
        }
    }

	function initCamera():Void {
		add(camFollow = new FlxObject(0, 0, 1, 1));
		moveCamera(stage.gf);

		if (lastCamFollow != null) {
			camFollow = lastCamFollow;
			lastCamFollow = null;
		}

		FlxG.camera.follow(camFollow, 0);
		FlxG.camera.snapToTarget();
		FlxG.camera.followLerp = Constants.CAMERA_LERP * cameraSpeed;
		FlxG.camera.zoom = cameraZoom = stage.data.cameraZoom;

		moveCamera(stage.dad);

		for (character in [stage.bf, stage.gf, stage.dad]) {
			character.onAnimPlay.add(updateCamera);
		}
	}

	public function moveCamera(character:Character):Void {
		if (disableCamera) return;

		target = Util.getCharacterTarget(character);

    	var xAdd:Float = target == 'gf' ? 0 : 150 * (target == 'dad' ? 1 : -1);
    
    	var newX:Float = character.getMidpoint().x + character.cameraPosition[0] + character.cameraOffset[0] + xAdd;
    	var newY:Float = character.getMidpoint().y + character.cameraPosition[1] + character.cameraOffset[1] - 100;
    
    	if (camFollow.x == newX && camFollow.y == newY) return;
    	camFollow.setPosition(newX, newY);
    }

	function updateCamera(name:String):Void {
		if (disableCamera) return;
		moveCamera(Util.getCharacter(target));
	}

	override function onBeat():Void {
		if (ended) return;

		for (char in [stage.bf, stage.dad, stage.gf]) {
			char.onBeatHit(curBeat);
		}

		for (icon in [ui.iconP1, ui.iconP2]) {
			icon.onBeatHit();
		}

		stage.onBeat(curBeat);
	}

	override function onStep():Void {
		if (ended) return;
		stage.onStep(curStep);
	}

	override function onMeasure():Void {
		if (ended) return;

		if (Data.cameraZooms && started && FlxG.camera.zoom < 1.35) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		stage.onMeasure(curMeasure);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (paused) return;

		unpauseSustainWindow = Util.bound(unpauseSustainWindow - 0.1 * elapsed, 0, unpauseSustainWindow);

		for (char in [stage.bf, stage.dad, stage.gf]) {
			char.stepLength = stepLength;
		}

		FlxG.camera.followLerp = Constants.CAMERA_LERP * cameraSpeed;

		if (started && !ended) {
			FlxG.camera.zoom = FlxMath.lerp(cameraZoom, FlxG.camera.zoom, Math.exp(-elapsed * 3.125));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 3.125));
		}

		triggerEvents();
	}

	public function triggerEvents():Void {
		if (events == null || events.length <= 0 || conductor.time < events[0].time) return;

		for (eventData in events[0].events) {
        	Event.trigger(eventData.name, eventData.values);
        }

		events.shift();
    }

		public function startSong(conductor:Conductor):Void {
        for (val in [inst, voices, opponentVoices]) {
            val?.play();
        }

        conductor.time = 0;
        conductor.song = inst;
        conductor.song.onComplete = endSong;
        started = true;
    }

	public function endSong():Void {
		if (PlayState.chartingMode) {
			FlxG.switchState(new ChartEditor());
			return;
		}

		if (PlayState.songs.length <= 0) return;

		PlayState.songs.shift();

		ended = true;
		canResync = false;

		if (PlayState.songs.length == 0) {
			FlxG.sound.music?.stop();
			FlxG.sound.playMusic(Path.music('freakyMenu'), 0.5);

            PlayState.resetProperties();

			if (PlayState.isStoryMode) {
				Rating.saveWeekScore(score);
				FlxG.switchState(new StoryMenuState());
			} else {
				Rating.saveFreeplayScore(score, percent);
				FlxG.switchState(new FreeplayState());
			}

			return;
		}

        PlayState.weekScore += PlayState.isStoryMode && (!PlayState.botplay || !PlayState.practiceMode) ? score : 0;
		PlayState.lastCamFollow = camFollow;

		skipNextTransIn = skipNextTransOut = true;

		FlxG.switchState(new PlayState());
	}

	public function togglePause(pause:Bool = true):Void {
		canResync = !pause;

		if (pause) {
			for (sound in [inst, voices, opponentVoices]) {
				sound?.pause();
			}

			FlxG.camera.followLerp = 0;
		} else {
			resyncVocals();
		}

		@:privateAccess for (tween in FlxTween.globalManager._tweens) if (!tween.finished) tween.active = !pause;
		@:privateAccess for (timer in FlxTimer.globalManager._timers) if (!timer.finished) timer.active = !pause;
		paused = conductor.paused = pause;
		persistentUpdate = !pause;
	}

	function prepareDeath():Void {
		openSubState(new GameOverSubState(ui.curStrumline.character));

		for (sound in [inst, voices, opponentVoices]) {
			sound?.stop();
		}

        FlxG.camera.followLerp = 0;
	}

	public function resyncVocals():Void {
        if (!started) return;

        inst.play();
        
        for (voices in [voices, opponentVoices]) {
            if (inst.time >= voices.length) {
                voices?.pause();
                break;
            }
            
            voices.time = inst.time;
            voices?.play();
        }
    }

	override function openSubState(SubState:FlxSubState):Void {
		super.openSubState(SubState);
		togglePause(true);
	}

	override function closeSubState():Void {
		super.closeSubState();
		togglePause(false);
	}

	function set_health(value:Float):Float {
		ui.healthBar.health = value = FlxMath.bound(value, 0, 1);

		if (value != 0 || PlayState.botplay || PlayState.practiceMode) return health = value;
		prepareDeath();

		return health = value;
	}

	override function destroy():Void {
		super.destroy();
		game = null;

		for (character in [stage.bf, stage.gf, stage.dad]) {
			character.onAnimPlay.remove(updateCamera);
		}
	}
}