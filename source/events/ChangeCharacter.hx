package events;

@event('Change Character')
class ChangeCharacter implements BaseEvent {
    public var meta:Array<EventMeta> = [
        new EventMeta('Character', 'character').list(['bf', 'dad', 'gf'], 'bf'),
        new EventMeta('Change to', 'changeTo').string('bf')
    ];

    public function execute(params:EventParams):Void {
        var character:Character = Util.getCharacter(params.string('character'));
        if (character == null) return;

        character.loadCharacter(params.string('changeTo'));
    }
}