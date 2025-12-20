package backend;

import animate.FlxAnimateFrames;
import objects.Character.CharacterData;
import haxe.Json;
import haxe.PosInfos;

import openfl.utils.Assets;
import openfl.system.System;
import openfl.display.BitmapData;
import openfl.media.Sound as OpenFLSound;

import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets;

import sys.FileSystem;

import moonchart.formats.fnf.legacy.FNFPsych;

@:keep class Path {
	public static var localAssets:Array<String> = [];
	public static var trackedImages:Map<String, FlxGraphic> = [];
	public static var trackedAudio:Map<String, OpenFLSound> = [];

	public static var exclusions:Array<String> = [
		'assets/music/freakyMenu.ogg', 'assets/music/breakfast.ogg',
		'assets/data/fonts/bitmap/default.png', 'assets/data/fonts/bitmap/default.fnt',
		'assets/data/fonts/bitmap/bold.png', 'assets/data/fonts/bitmap/bold.fnt',
		'assets/data/fonts/bitmap/vcr.png', 'assets/data/fonts/bitmap/vcr.fnt',
		'assets/images/misc/transition.png'
	];

	public static function get(key:String, ?pos:PosInfos):String {
		if (!FileSystem.exists('assets/$key')) {
			if (Constants.VERBOSE) trace('$key could not be found: $pos');
			return null;
		}

		return 'assets/$key';
	}

	public static function preloadGameAssets(skin:String, song:String):Void {
		for (sound in ['uiSkins/$skin/three', 'uiSkins/$skin/two', 'uiSkins/$skin/one', 'uiSkins/$skin/go', 'firstDeath', 'deathConfirm']) {
			Path.sound(sound);
		}

		for (audio in ['songs/$song/Inst', 'songs/$song/Voices-Player', 'songs/$song/Voices-Opponent']) {
			Path.audio(audio);
		}

		for (i in 1...3) {
			Path.sound('miss$i');
		}

		Path.music('deathLoop');
		Path.music('breakfast');

		for (name in ['sick', 'good', 'bad', 'shit', 'healthBar', 'ready', 'set', 'go']) {
			Path.image('uiSkins/$skin/$name');
		}

		for (i in 0...10) {
			Path.image('uiSkins/$skin/num$i');
		}
	}

	public static function preloadAudio(audio:String):Void {
		final output:Array<String> = audio.split(':');
		Path.audio(output[1] != null ? '${output[1]}/${output[0]}' : output[0]);
	}

	public static function preloadImage(image:String):Void {
		final output:Array<String> = image.split(':');
		Path.image(output[0], output[1] ?? 'images');
	}

	public static function image(key:String, ?prefix:String = 'images'):FlxGraphic {
		localAssets.push(key);

		if (!trackedImages.exists(key)) {
			final bitmap:BitmapData = BitmapData.fromFile(get('$prefix/$key.png'));
			if (bitmap == null) return null;

			if (Data.gpuRendering) bitmap.disposeImage();

			final graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
			graphic.persist = true;
			trackedImages.set(key, graphic);
		}

		return trackedImages[key];
	}

	public static function audio(key:String):OpenFLSound {
		localAssets.push(key);

		if (!trackedAudio.exists(key)) {
			trackedAudio.set(key, OpenFLSound.fromFile(get('$key.ogg')) ?? FlxAssets.getSoundAddExtension('flixel/sounds/beep'));
		}

		return trackedAudio[key];
    }

	inline public static function song(key:String, song:String):FlxSound {
		return FlxG.sound.load(Path.audio('songs/$song/$key'));
	}

	inline public static function chart(song:String, difficulty:String):Chart {

		/**
		//this code will be used for importing psych engine charts inside of the chart editor, i decided i wont be supporting other chart formats
		var chartPath:String = Path.json('songs/$song/$difficulty');
		var legacyJson = new FNFPsych().fromFile(chartPath);

		var chart:Chart = {
			song: legacyJson.data.song.song,
			speed: legacyJson.data.song.speed,
			bpm: legacyJson.data.song.bpm,
			stage: legacyJson.data.song.stage,
			player1: legacyJson.data.song.player1,
			player2: legacyJson.data.song.player2,
			player3: legacyJson.data.song.player3,
			events: Json.parse(File.getContent(chartPath)).song.events,
			notes: []
		};

		var time:Float = 0;
		var currentBPM:Float = chart.bpm;

		for (note in new FNFPsych().fromFile(chartPath).getNotes()) {
			chart.notes.push({data: note.lane, time: note.time, length: note.length, type: note.type ?? ''});
		}

		for (i => section in legacyJson.data.song.notes) {
			var intendedBPM:Null<Float> = (section.changeBPM) ? section.bpm : null;

			if (intendedBPM != null && intendedBPM != currentBPM) {
				currentBPM = intendedBPM;
			}

			if (chart.events[i] != null && chart.events[i].time == time) {
				chart.events[i].events.push({
					name: 'Focus Camera',
					values: [
						{name: 'character', value: section.mustHitSection ? 'bf' : 'dad'},
						{name: 'classic', value: 'true'}
					]
				});
			} else {
				chart.events.push({
					time: time,
					events: [{
						name: 'Focus Camera',
						values: [
							{name: 'character', value: section.mustHitSection ? 'bf' : 'dad'},
							{name: 'classic', value: 'true'}
						]
					}]
				});
			}

			if (section.changeBPM) {
				if (chart.events[i] != null && chart.events[i].time == time) {
					chart.events[i].events.push({
						name: 'Set Song BPM',
						values: [
							{name: 'bpm', value: '${section.bpm}'},
							{name: 'duration', value: '0'}
						]
					});
				} else {
					chart.events.push({
						time: time,
						events: [{
							name: 'Set Song BPM',
							values: [
							{name: 'bpm', value: '${section.bpm}'},
							{name: 'duration', value: '0'}
							]
						}]
					});
				}
			}

			time += (60 / currentBPM) * 4000;
		}

		chart.events.sort(byTime);

		return chart;
		**/

		return parseJSON(Path.json('songs/$song/$difficulty'));
	}

	inline public static function parseJSON(key:String):Dynamic {
		return Json.parse(File.getContent(key));
	}

	inline public static function font(key:String):String {
		return get('data/fonts/$key');
	}

	inline public static function fnt(key:String):String {
		return get('$key.fnt');
	}

	inline public static function video(key:String):String {
		return get('videos/$key.mp4');
	}

	inline public static function xml(key:String):String {
		return get('$key.xml');
	}

	inline public static function txt(key:String):String {
		return get('$key.txt');
	}

	inline public static function json(key:String):String {
		return get('$key.json');
	}

	inline public static function stage(key:String):StageData {
		return parseJSON(json('data/stages/$key'));
	}

	inline public static function character(key:String):CharacterData {
		return parseJSON(json('data/characters/$key/$key'));
	}

	inline public static function characterPath(key:String):String {
		return get('data/characters/$key');
	}

	inline public static function sound(key:String):OpenFLSound {
		return audio('sounds/$key');
	}

	inline public static function music(key:String):OpenFLSound {
		return audio('music/$key');
	}

	public static function multiSparrow(keys:Array<String>, ?prefix:String = 'images'):FlxAtlasFrames {
		var parentFrames:FlxAtlasFrames = Path.sparrow(keys[0].trim(), prefix);

		if (keys.length > 1) {
			var original:FlxAtlasFrames = parentFrames;

			parentFrames = new FlxAtlasFrames(parentFrames.parent);
			parentFrames.addAtlas(original, true);

			for (i in 1...keys.length) {
				var extraFrames:FlxAtlasFrames = Path.sparrow(keys[i].trim(), prefix);
				if (extraFrames != null) parentFrames.addAtlas(extraFrames, true);
			}
		}

		return parentFrames;
	}

	inline public static function sparrow(key:String, ?prefix:String = 'images'):FlxAtlasFrames {
		return FlxAtlasFrames.fromSparrow(image(key, prefix), xml('$prefix/$key'));
	}

	public static function animateAtlas(key:String, ?prefix:String = 'images'):FlxAnimateFrames {
		return FlxAnimateFrames.fromAnimate(Path.get('$prefix/$key'));
	}

	inline public static function exists(key:String):Bool {
		return FileSystem.exists('assets/$key') ? true : false;
	}

	public static function clearUnusedMemory():Void {
		for (key in trackedImages.keys()) {
			if (!localAssets.contains(key) && !exclusions.contains(key)) {
				FlxG.bitmap.remove(trackedImages[key]);
				trackedImages.remove(key);
			}
		}

		for (key in trackedAudio.keys()) {
			if (!localAssets.contains(key) && !exclusions.contains(key)) {
				Assets.cache.clear(key);
				trackedAudio.remove(key);
			}
		}

		System.gc();
	}

	public static function clearStoredMemory():Void {
		clearUnusedMemory();
		localAssets = [];
	}
}