package events;

@event('Change Scroll Speed')
class ChangeScrollSpeed implements BaseEvent {
    public var meta:Array<EventMeta> = [
        new EventMeta('Speed', 'speed').float(0.05, 1.0),
        new EventMeta('Duration', 'duration').float(0.05, 1.0),
        new EventMeta('Ease', 'ease').list(['linear', 'back', 'bounce', 'circ', 'cube', 'elastic', 'expo', 'quad', 'quart', 'quint', 'sine', 'smoothStep', 'smootherStep'], 'linear'),
        new EventMeta('Ease Direction', 'easeDir').list(['In', 'Out', 'InOut'], '').when('ease!=linear')
    ];

    public function execute(params:EventParams):Void {
        var speed:Float = params.float('speed');
        var duration:Float = params.float('duration');
        var ease:String = params.string('ease');
        var easeDir:String = params.string('easeDir');

        duration > 0 ? FlxTween.num(game.scrollSpeed, speed, duration, {ease: Util.getEase(ease + easeDir)}, setScrollSpeed) : game.scrollSpeed = speed;
    }

    function setScrollSpeed(value:Float):Void {
        game.scrollSpeed = value;
    }
}