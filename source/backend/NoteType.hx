package backend;

import objects.BaseNote;

class NoteType {
    public static var noteTypes:Map<String, Class<BaseNote>> = new Map();

    public static function get(name:String):BaseNote {
        if (!noteTypes.exists(name) || name == null) {
            if (Constants.VERBOSE) trace('Warning: Note type "$name" not found.');
            return null;
        }

        return Type.createInstance(noteTypes[name], []);
    }
}