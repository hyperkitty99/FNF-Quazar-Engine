package backend;

import backend.Chart.EventValue;
import objects.BaseEvent;

class Event {
    public static var events:Map<String, Class<BaseEvent>> = new Map();

    public static function trigger(name:String, values:Array<EventValue>):Void {
        if (!events.exists(name) || name == null || values == null) {
            if (Constants.VERBOSE) trace('Warning: Event "$name" not found.');
            return;
        }

        Type.createInstance(events[name], []).execute(new EventParams(values));
    }
}