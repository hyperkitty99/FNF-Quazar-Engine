package backend;

typedef WeekJSON = {
    name:String, desc:String, titleImage:String, weekBefore:String,
    characters:Array<String>, songs:Array<SongData>, ?difficulties:Array<DiffData>,

    ?locked:Bool, ?hideStory:Bool, ?hideFreeplay:Bool
}

typedef DiffData = {name:String, displayName:String}
typedef SongData = {name:String, ?displayName:String, ?charter:String, ?artist:String, icon:String, color:String, ?diff:Array<DiffData>, ?week:Int}

class WeekData {
    public static var loadedWeeks:Map<String, WeekData> = new Map();
	public static var weeks:Array<String> = [];

    public var name:String;
    public var desc:String;
    public var titleImage:String;
    public var weekBefore:String;

    public var characters:Array<String> = [];
    public var songs:Array<SongData> = [];
    public var difficulties:Array<DiffData> = [];

    public var locked:Bool;
    public var hideStory:Bool;
    public var hideFreeplay:Bool;

    public function new(week:WeekJSON):Void {
        if (week == null) week = WeekData.create();

        name = week.name;
        desc = week.desc;
        titleImage = week.titleImage;
        weekBefore = week.weekBefore;
        characters = week.characters;
        songs = week.songs;
        difficulties = week.difficulties != null ? week.difficulties : [{name: 'normal', displayName: 'Normal'}];
        if (week.locked != null) locked = week.locked;
        if (week.hideStory != null) hideStory = week.hideStory;
        if (week.hideFreeplay != null) hideFreeplay = week.hideFreeplay;
    }

    public static function create():WeekJSON {
		return {
            name: 'Custom Week',
            desc: 'Description',
            titleImage: 'week1',
            weekBefore: 'tutorial',
			songs: [
                {name: 'Bopeebo', icon: 'face', color: '#9271fd'},
                {name: 'Fresh', icon: 'face', color: '#9271fd'},
                {name: 'Dad Battle', icon: 'face', color: '#9271fd'}
            ],
			characters: ['dad', 'gf', 'bf']
        };
	}

    public static function reload():Void {
        final weeksPath:String = 'assets/data/weeks';

		for (file in FileSystem.readDirectory(weeksPath)) {
			final path:String = '$weeksPath/$file';

            if (FileSystem.isDirectory(path) || !file.endsWith('.json')) continue;

			WeekData.add(file.substr(0, file.length - 5), path);
		}

        loadSongMeta();
    }

    static function loadSongMeta():Void {
        for (week in weeks) {

            for (song in loadedWeeks[week].songs) {
                var metaPath:String = 'assets/songs/${song.name}/metadata.json';

                if (!FileSystem.exists(metaPath) || FileSystem.isDirectory(metaPath)) continue;

                try {
                    var songMeta = haxe.Json.parse(File.getContent(metaPath));

                    if (songMeta.difficulties != null) {
                        song.diff = songMeta.difficulties;
                    }

                    if (songMeta.song != null) {
                        song.displayName = songMeta.song;
                    }

                    if (songMeta.artist != null) {
                        song.artist = songMeta.artist;
                    }

                    if (songMeta.charter != null) {
                        song.charter = songMeta.charter;
                    }
                } catch(e:Dynamic) {
                    if (Constants.VERBOSE) trace('Error loading metadata for ${song.name}: $e');
                }
            }
        }
    }

    static function add(weekToCheck:String, path:String):Void {
        if (loadedWeeks.exists(weekToCheck)) return;

		var week:WeekJSON = WeekData.getFile(path);
        if (week == null) return;

		var weekFile:WeekData = new WeekData(week);

		if ((PlayState.isStoryMode && !weekFile.hideStory) || (!PlayState.isStoryMode && !weekFile.hideFreeplay)) {
			loadedWeeks.set(weekToCheck, weekFile);
			weeks.push(weekToCheck);
		}
	}

    static function getFile(path:String):WeekJSON {
		var rawJson:String = FileSystem.exists(path) ? File.getContent(path) : null;
        return (rawJson != null && rawJson.length > 0) ? haxe.Json.parse(rawJson) : null;
	}

    public static function getName(num:Int = null):String {
		return WeekData.weeks[num == null ? PlayState.curWeek : num];
	}

	public static function getCurrent(num:Int = null):WeekData {
		return WeekData.loadedWeeks[WeekData.weeks[num == null ? PlayState.curWeek : num]];
	}

    public static function isLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.loadedWeeks.get(name);
		return (leWeek.locked && leWeek.weekBefore.length > 0 && (!Data.completedWeeks.exists(leWeek.weekBefore) || !Data.completedWeeks.get(leWeek.weekBefore)));
	}
}