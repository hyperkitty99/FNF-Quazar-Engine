package objects;

import haxe.ds.ArraySort;
import flixel.util.FlxStringUtil;
import objects.HeathBar;

class UI extends FlxGroup {
    public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var healthBar:HealthBar;
	public var scoreText:BitmapText;
	public var comboGroup:FlxSpriteGroup;

	public var playerStrum:Strumline;
	public var opponentStrum:Strumline;

	public var curStrumline(get, default):Strumline;

    public function new(camera:FlxCamera):Void {
        super();

		if (camera != null) this.camera = camera;

		add(opponentStrum = new Strumline(50, 0, camera, PlayState.botplay));
		opponentStrum.x = opponentStrum.skinData.meta.position[0];
		opponentStrum.y = Data.downScroll ? FlxG.height - opponentStrum.strums[0].height - opponentStrum.skinData.meta.position[1] : opponentStrum.skinData.meta.position[1];
		opponentStrum.visible = Data.opponentNotes;
		opponentStrum.character = game.stage.dad;
		opponentStrum.voices = game.opponentVoices;

		add(playerStrum = new Strumline(0, opponentStrum.y, camera, PlayState.botplay, true));
        playerStrum.x = FlxG.width - playerStrum.width - playerStrum.skinData.meta.position[0];
		playerStrum.character = game.stage.bf;
		playerStrum.voices = game.voices;

		createNotes();

		add(healthBar = new HealthBar(FlxG.height * (Data.downScroll ? 0.1 : 0.9), opponentStrum.player));
		healthBar.loadColors(game.chart.player1, game.chart.player2);

		add(iconP1 = new HealthIcon(0, healthBar.y - 75, game.chart.player1, true));
		add(iconP2 = new HealthIcon(0, healthBar.y - 75, game.chart.player2));

        add(scoreText = new BitmapText(healthBar.x + healthBar.width - 190, healthBar.y + 30, 'vcr', PlayState.botplay ? 'Bot Play Enabled' : 'Score: 0'));
        scoreText.setFormat('vcr', 0.8, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        scoreText.borderSize = 2;

        add(comboGroup = new FlxSpriteGroup());

		iconP1.visible = iconP2.visible = healthBar.visible = scoreText.visible = comboGroup.visible = !Data.hideHud;

		PlayState.skipCountdown ? game.startSong(game.conductor) : add(new Countdown(game.conductor, game.startSong.bind(game.conductor)));
    }

	function get_curStrumline():Strumline {
		if (opponentStrum == null || playerStrum == null) return null;
		return playerStrum.player ? playerStrum : opponentStrum;
	}

	function createNotes():Void {
		var notes:Map<String, NoteJSON> = [];

		for (note in game.chart.notes) {
			var hash:String = '${note.data}_${note.time}';
			if (notes.exists(hash)) continue;

			notes.set(hash, note);
			(note.data > 3 ? playerStrum : opponentStrum).noteData.push(note);
		}

		notes.clear();

		for (strumline in [opponentStrum, playerStrum]) {
			ArraySort.sort(strumline.noteData, Util.sortByNoteTime);
		}
	}

    override function update(elapsed:Float):Void {
		super.update(elapsed);

		for (i => icon in [iconP1, iconP2]) {
    		icon.scale.x = icon.scale.y = FlxMath.lerp(1, icon.scale.x, Math.exp(-elapsed * 9));
    		icon.updateHitbox();
			icon.x = healthBar.opponentBar.x + healthBar.opponentBar.clipRect.width - (20 + (i * 100));
    		icon.animation.curAnim.curFrame = (i == (opponentStrum.player ? 1 : 0) ? (healthBar.health < 0.2) : (healthBar.health > 0.8)) ? 1 : 0;
		}

		scoreText.text = PlayState.botplay ? 'Bot Play Enabled' : 'Score: ${FlxStringUtil.formatMoney(game.score, false, true)}';
	}
}