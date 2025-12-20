package states.editors;

import flixel.ui.FlxButton;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.waveform.FlxWaveform;
import flixel.addons.ui.*;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

class ChartEditor extends MusicScene {
	public static var chart:Chart;

	public static inline var GRID_SIZE:Int = 40;

	public static var curQuant:Int = 3;

	var inst:FlxSound;
	var voices:FlxSound;
	var voicesOpponent:FlxSound;

	var gridBG:FlxSprite;
	var selectedBox:FlxSprite;
	var timeline:FlxSprite;

	var lines:FlxSpriteGroup;

	var sustains:FlxTypedGroup<ChartSustain>;
	var notes:FlxTypedGroup<ChartNote>;
	var events:FlxTypedGroup<ChartEvent>;

	var iconP1:HealthIcon;
	var iconP2:HealthIcon;

	var selectedNote:NoteJSON;
	var selectedEvent:EventJSON;

	var playerHitVolume:Float = 1;
	var opponentHitVolume:Float = 1;

	var playerWaveform:FlxWaveform;
	var opponentWaveform:FlxWaveform;

	var time(get, set):Float;
	var lastTime:Float;

	var chartInfo:FlxUITabMenu;

	var _file:FileReference;

	public function new(chart:Chart = null):Void {
		super();
		ChartEditor.chart = (PlayState.chartingMode ? ChartEditor.chart : chart) ?? Path.chart('Test', 'normal');
	}

	override public function create():Void {
		super.create();

		PlayState.chartingMode = true;

		bgColor = 0xFF252525;

		inst = Path.song('Inst', chart.song.toLowerCase());
		voices = Path.song('Voices-Player', chart.song.toLowerCase());
		voicesOpponent = Path.song('Voices-Opponent', chart.song.toLowerCase());

		conductor.paused = true;
		conductor.bpm = chart.bpm;
		conductor.song = inst;

		for (val in [inst, voices, voicesOpponent]) {
			val.play();
			val.pause();
		}

		final bitmapGrid = FlxGridOverlay.createGrid(GRID_SIZE, GRID_SIZE, GRID_SIZE * 9, GRID_SIZE * 16, true, 0xFFAAAAAA, 0xFF616060);

		add(gridBG = new FlxTiledSprite(bitmapGrid, GRID_SIZE * 9, GRID_SIZE * 16));
		gridBG.x = 440;

		add(lines = new FlxSpriteGroup());

		add(selectedBox = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(GRID_SIZE, GRID_SIZE));

		add(sustains = new FlxTypedGroup());
		add(notes = new FlxTypedGroup());
		add(events = new FlxTypedGroup());

		add(timeline = new FlxSprite(440, 100).makeGraphic(Std.int(gridBG.width), 4, 0x50FF0000));
		timeline.scrollFactor.set();

		add(playerWaveform = new FlxWaveform(gridBG.x + gridBG.width - 20, 100, 80, FlxG.height * 3, 0x00FFFFFF, 0x00FF0000, COMBINED));
		playerWaveform.loadDataFromFlxSound(voices);
		playerWaveform.scrollFactor.set();

		add(opponentWaveform = new FlxWaveform(gridBG.x - 60, 100, 80, FlxG.height * 3, 0x00FFFFFF, 0x00FF0000, COMBINED));
		opponentWaveform.loadDataFromFlxSound(voicesOpponent);
		opponentWaveform.scrollFactor.set();

        playerWaveform.waveformRMSColor = opponentWaveform.waveformRMSColor = 0xFFFFFFFF;
        playerWaveform.waveformDrawBaseline = opponentWaveform.waveformDrawBaseline = playerWaveform.waveformDrawRMS = opponentWaveform.waveformDrawRMS = true;
        playerWaveform.waveformOrientation = opponentWaveform.waveformOrientation = VERTICAL;

		add(iconP2 = new HealthIcon(gridBG.x - 94, 25, chart.player2));
		iconP2.scrollFactor.set();
		iconP2.scale.set(0.5, 0.5);
		iconP2.updateHitbox();

		add(iconP1 = new HealthIcon(gridBG.x + gridBG.width - 54, 25, chart.player1, true));
		iconP1.scrollFactor.set();
		iconP1.scale.set(0.5, 0.5);
		iconP1.updateHitbox();

		regenGrid();

		//kill me
		Key.onPress([FlxKey.ENTER], onBack);
		Key.onPress([FlxKey.SPACE], toggleSong);
		Key.onPress([FlxKey.P], setTime.bind(inst.length));
		Key.onPress([FlxKey.O], setTime.bind(0));
		Key.onHold([FlxKey.A], moveSection.bind(-1));
		Key.onHold([FlxKey.D], moveSection.bind(1));
		Key.onHold(Key.up, moveStep.bind(-4));
		Key.onHold(Key.down, moveStep.bind(4));
		Key.onPress([FlxKey.LEFT], onQuantChange.bind(-1));
		Key.onPress([FlxKey.RIGHT], onQuantChange.bind(1));
		Key.onPress([FlxKey.Q], adjustSustain.bind(-1));
		Key.onPress([FlxKey.E], adjustSustain.bind(1));

		chart.notes.iter(createNote);
		chart.events.iter(createEvent);

		var tabs:Array<{name:String, label:String}> = [
			{name: 'Song', label: 'Song'},
			{name: 'Section', label: 'Section'},
			{name: 'Note', label: 'Note'},
			{name: 'Event', label: 'Event'},
			{name: 'Charting', label: 'Charting'}
		];

		add(chartInfo = new FlxUITabMenu(tabs, true));
		chartInfo.selected_tab_id = 'Song';
		chartInfo.scrollFactor.set();
		chartInfo.x = chartInfo.y = 20;
		chartInfo.resize(250, 320);

		addSongUI();
	}

	var speed:Float;
	function addSongUI() {
		var tab_group = new FlxUI(chartInfo);
		tab_group.name = 'Song';

		speed = chart.speed;

		tab_group.add(new FlxButton(15, 15, 'Save', saveChart));
		tab_group.add(new FlxButton(110, 15, 'Reload Chart', () -> {
			ChartEditor.chart = Path.chart(chart.song, PlayState.difficulty);
			FlxG.switchState(new ChartEditor());
		}));

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(15, 70, 1, 1, 1, 400, 3);
		stepperBPM.value = conductor.bpm;
		stepperBPM.name = 'song_bpm';

		tab_group.add(new FlxText(stepperBPM.x, stepperBPM.y - 15, 0, 'Song BPM:'));
		tab_group.add(stepperBPM);

		var nullThing:Null<Int> = null;

		var speedSlider:FlxUISlider = new FlxUISlider(this, 'speed', 10, 100, 0.1, 10, 210, nullThing, 5, FlxColor.WHITE, FlxColor.BLACK);
		speedSlider.nameLabel.text = 'Scroll Speed:';
		speedSlider.value = chart.speed;
		speedSlider.decimals = 1;
		speedSlider.callback = function(relativePos:Float) {
			chart.speed = speed;
		};

		tab_group.add(speedSlider);

		chartInfo.addGroup(tab_group);
	}

	function regenGrid():Void {
		var section:Float = inst.length / measureLength;

		gridBG.height = GRID_SIZE * 16 * section;

		lines.clear();

		for (i in 0...Math.floor(section)) {
			lines.add(new FlxSprite(gridBG.x, getYfromStrum(measureLength * i)).makeGraphic(Std.int(gridBG.width), 2, 0xFF000000));
		}

		lines.add(new FlxSprite(gridBG.x + 160).makeGraphic(2, Std.int(gridBG.height), 0xFF000000));
		lines.add(new FlxSprite(gridBG.x + 320).makeGraphic(2, Std.int(gridBG.height), 0xFF000000));
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>):Void {
		if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			var nums:FlxUINumericStepper = cast sender;
	
			switch(nums.name) {
				case 'song_bpm':
					chart.bpm = conductor.bpm = nums.value;
					regenGrid();
                	repositionAll();
			}
		}
	}

	function repositionAll():Void {
    	for (note in notes) {
    	    note.y = getYfromStrum(note.data.time);
    	}

    	for (sustain in sustains) {
    	    var noteSpr = notes.members.find(n -> n.data == sustain.data);

			if (noteSpr == null) continue;
    	    sustain.y = noteSpr.y + (noteSpr.height * 0.5);
    	    sustain.setHeight(sustain.data.length, stepLength);
    	}

    	for (event in events) {
    	    event.y = getYfromStrum(event.data.time);
    	}
	}

	function onBack():Void {
		FlxG.switchState(new PlayState());
	}

	function toggleSong():Void {
		conductor.paused = !conductor.paused;
		for (val in [inst, voices, voicesOpponent]) {
			conductor.paused ? val.pause() : val.resume();
		}
	}

	function setTime(value:Float):Void {
		time = value;

		if (conductor.paused) return;
		toggleSong();
	}

	function moveSection(dir:Int):Void {
		time = FlxMath.bound((curMeasure + dir * (FlxG.keys.pressed.SHIFT ? 4 : 1)) * measureLength, 0, inst.length);
	}

	function moveStep(dir:Int):Void {
		time = FlxMath.bound((curStep + dir) * stepLength, 0, inst.length); //cant just divide measureLength because time signatures exist
	}

	function onQuantChange(dir:Int):Void {
		curQuant = (curQuant + dir + Constants.QUANTS.length) % Constants.QUANTS.length;
	}

	function createNote(note:NoteJSON):Void {
		notes.add(new ChartNote(note.data * GRID_SIZE + gridBG.x, getYfromStrum(note.time), note));

		if (note.length <= 0) return;
		createSustain(note);
	}

	function createSustain(note:NoteJSON):Void {
		var noteSpr = notes.members.find(n -> n.data == note);
		if (noteSpr == null) return;

		sustains.add(new ChartSustain(noteSpr.x + (noteSpr.width - 4) * 0.5, noteSpr.y + (noteSpr.height * 0.5), note, stepLength));
	}

	function createEvent(event:EventJSON):Void {
		events.add(new ChartEvent(8 * GRID_SIZE + gridBG.x, getYfromStrum(event.time), event));
	}

	function removeNote(note:NoteJSON):Void {
		chart.notes.remove(note);

		var visualNote = notes.members.find(n -> n.data == note);
		if (visualNote == null) return;

		notes.remove(visualNote, true);
		removeSustain(note);
	}

	function removeSustain(note:NoteJSON):Void {
		var sustain = sustains.members.find(s -> s.data == note);
		if (sustain == null) return;

		sustains.remove(sustain, true);
	}

	function removeEvent(event:EventJSON):Void {
		chart.events.remove(event);

		var visualEvent = events.members.find(e -> e.data == event);
		if (visualEvent == null) return;

		events.remove(visualEvent, true);
	}

	function addNote():Void {
		var direction = Math.floor((FlxG.mouse.x - GRID_SIZE) / GRID_SIZE) - 10;
		if (direction > 7) return;

		selectedNote = {time: getStrumTime(selectedBox.y), data: direction, length: 0};

		chart.notes.push(selectedNote);
		createNote(selectedNote);
	}

	function adjustSustain(delta:Int = 0):Void {
		if (selectedNote == null) return;

		selectedNote.length += FlxG.keys.pressed.SHIFT ? (stepLength * delta) * 2 : (stepLength * delta);
		if (selectedNote.length < 0) selectedNote.length = 0;

		var sustain = sustains.members.find(s -> s.data == selectedNote);

		selectedNote.length > 0 ? (sustain != null ? sustain.setHeight(selectedNote.length, stepLength) : createSustain(selectedNote)) : removeSustain(selectedNote);
	}


	function addEvent():Void {
		var direction = Math.floor((FlxG.mouse.x - GRID_SIZE) / GRID_SIZE) - 10;
		if (direction < 8) return;

		selectedEvent = {time: getStrumTime(selectedBox.y), events: []};

		chart.events.push(selectedEvent);
		createEvent(selectedEvent);
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (FlxG.mouse.wheel != 0) {
			moveStep(FlxG.mouse.wheel > 0 ? -1 : 1);

			if (!conductor.paused) {
				toggleSong();
			}
		}

		FlxG.camera.scroll.y = getYfromStrum(time) - 100;

		checkNoteHits();
		mouseInput();

		lastTime = time;

		playerWaveform.waveformTime = opponentWaveform.waveformTime = time;
	}

	var hitOffset:Float = 15;
	function checkNoteHits():Void {
		if (!conductor.song.playing) return;

		for (note in notes.members.filter(visibleNote)) {
			if (note.data.time > time + hitOffset || note.data.time <= lastTime + hitOffset) continue;

			FlxG.sound.play(Path.sound('hitsound'), note.data.data > 3 ? playerHitVolume : opponentHitVolume);
		}
	}

	function mouseInput():Void {
		if (!FlxG.mouse.overlaps(gridBG)) {
			selectedBox.setPosition(-FlxG.width, -FlxG.height);

			if (!FlxG.mouse.justPressed) return;

			selectedNote = null;
			selectedEvent = null;

			return;
		}

		var gridmult:Float = GRID_SIZE / (Constants.QUANTS[curQuant] / 16);
		selectedBox.setPosition(Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE, Math.floor(FlxG.mouse.y / gridmult) * gridmult);

		//HACK: Hacky way to get an overlapped group, but it's less code so it will do for now...
		if (FlxG.mouse.justPressed) {
			var overlappedNote = notes.getOverlapped(visibleNote);
			overlappedNote != null ? selectedNote = overlappedNote.data : addNote();

			var overlappedEvent = events.getOverlapped(visibleEvent);
			overlappedEvent != null ? selectedEvent = overlappedEvent.data : addEvent();
		}

		if (!FlxG.mouse.pressedRight) return;

		var noteToRemove = notes.getOverlapped(visibleNote);
		if (noteToRemove != null) {
			removeNote(noteToRemove.data);
		}

		var eventToRemove = events.getOverlapped(visibleEvent);
		if (eventToRemove != null) {
			removeEvent(eventToRemove.data);
		}
	}

	function visibleNote(note:ChartNote):Bool {
		return note.isOnScreen();
	}

	function visibleEvent(event:ChartEvent):Bool {
		return event.isOnScreen();
	}

	function getYfromStrum(time:Float):Float {
		return FlxMath.remapToRange(time, 0, 16 * stepLength, gridBG.y, gridBG.y + (GRID_SIZE * 16));
	}

	function getStrumTime(y:Float):Float {
		return FlxMath.remapToRange(y, gridBG.y, gridBG.y + (GRID_SIZE * 16), 0, 16 * stepLength);
	}

	function get_time():Float {
		return conductor.time;
	}

	function set_time(value:Float):Float {
		conductor.time = value;

		for (val in [inst, voices, voicesOpponent, conductor.song]) {
			val.time = value;
		}
		return value;
	}

	function saveChart():Void {
		if (chart.events != null && chart.events.length > 1) {
			chart.events.sort(Util.sortByEventTime);
		}

		if (chart.notes != null && chart.notes.length > 1) {
			chart.notes.sort(Util.sortByNoteTime);
		}

		var data:String = haxe.Json.stringify(chart, '\t');

		if (data == null || data.length <= 0) return; 

		_file = new FileReference();
		_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.addEventListener(Event.CANCEL, onSaveCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file.save(data.trim(), 'normal.json');
	}

	function reset_file():Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onSaveComplete(_):Void {
		reset_file();
		FlxG.log.notice('Successfully saved chart.');
	}

	function onSaveCancel(_):Void {
		reset_file();
	}

	function onSaveError(_):Void {
		reset_file();
		FlxG.log.error('An error has occured while saving the chart.');
	}

	static function sortEventbyTime(a:EventJSON, b:EventJSON):Int {
		return (a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
	}

	static function sortNotebyTime(a:NoteJSON, b:NoteJSON):Int {
		return (a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
	}
}

/**
	BUGs:
    - The song stops playing after it reaches the finish line.  (still open)
    - When opening the Chart Editor for the second time, the chart resets. [FIXED]
    - Dispatched Events disappear from the Chart Editor after Playtesting the chart. [FIXED]

    TODOs:
    • Player/Opponent Icons [DONE]
    • Hit sounds [DONE]
    • Audio waveforms [DONE]
    • User Interface [WIP]
    • Replace flixel‑ui with haxe‑ui
    • Import / Export chart files
    • Remove all anonymous functions
    • Adjust visuals to BPM changes [DONE]
    • Support different Time signatures
**/