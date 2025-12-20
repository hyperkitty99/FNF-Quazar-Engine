package objects;

import flixel.group.FlxContainer;

class BaseStage extends FlxContainer {
    public var props:Map<String, FlxSprite> = new Map();

    public var gf:Character;
    public var dad:Character;
    public var bf:Character;

    public var data:StageData;
    public var name:String;

    var prevBgColor:Int;

    public function new(name:String, player1:String = 'bf', player2:String = 'dad', player3:String = 'gf'):Void {
        super();

        prevBgColor = FlxG.camera.bgColor;

        add(gf = new Character(player3));
        add(dad = new Character(player2));
        add(bf = new Character(player1, true));

        gf.onAnimPlay.add(onGFAnim);
        dad.onAnimPlay.add(onDadAnim);
        bf.onAnimPlay.add(onBFAnim);

        load(name);
        create();
    }

    function onBFAnim(animation:String):Void {}
    function onGFAnim(animation:String):Void {}
    function onDadAnim(animation:String):Void {}

    public function load(stage:String):Void {
        data = Path.stage(name = stage);

        if (props != null) {
            for (prop in props) {
                remove(prop, true);
                prop.destroy();
                prop = null;
            }
        }

        gf.setPosition(data.gf.position[0], data.gf.position[1]);
        dad.setPosition(data.dad.position[0], data.dad.position[1]);
        bf.setPosition(data.bf.position[0], data.bf.position[1]);

        gf.cameraPosition = data.gf.cameraPosition;
        dad.cameraPosition = data.dad.cameraPosition;
        bf.cameraPosition = data.bf.cameraPosition;

        if (data.gf.scroll != null) gf.scrollFactor.set(data.gf.scroll[0], data.gf.scroll[1]);
        if (data.dad.scroll != null) dad.scrollFactor.set(data.dad.scroll[0], data.dad.scroll[1]);
        if (data.bf.scroll != null) bf.scrollFactor.set(data.bf.scroll[0], data.bf.scroll[1]);

        if (data.bgColor != null) {
            FlxG.camera.bgColor = FlxColor.fromString(data.bgColor);
        }

        gf.visible = !data.gf.hide;
        dad.visible = !data.dad.hide;
        bf.visible = !data.bf.hide;

        gf.zIndex = data.gf.zIndex;
        dad.zIndex = data.dad.zIndex;
        bf.zIndex = data.bf.zIndex;

        if (data.objects == null) return;

        for (obj in data.objects) {
            var sprite:FlxSprite = new FlxSprite(obj.position[0], obj.position[1]);

            if (obj.animations != null) {
                for (animData in obj.animations) {
                    if (animData.indices == null || animData.indices.length == 0) {
                        sprite.animation.addByPrefix(animData.name, animData.prefix, animData.fps, animData.looped);
                    } else {
                        sprite.animation.addByIndices(animData.name, animData.prefix, animData.indices, '', animData.fps, animData.looped);
                    }
                }
            } else {
                sprite.loadGraphic(Path.image(obj.path, data.imagePath != null ? data.imagePath : obj.prefix != null ? obj.prefix : 'images/stages/$name'));
            }

            if (obj.scroll != null) sprite.scrollFactor.set(obj.scroll[0], obj.scroll[1]);
            if (obj.scale != null) sprite.scale.set(obj.scale[0], obj.scale[1]);
            if (obj.color != null) sprite.color = FlxColor.fromString(obj.color);
            if (obj.angle != null) sprite.angle = obj.angle;
            if (obj.alpha != null) sprite.alpha = obj.alpha;
            if (obj.flipX != null) sprite.flipX = obj.flipX;
            if (obj.flipY != null) sprite.flipY = obj.flipY;

            sprite.zIndex = obj.zIndex;
            sprite.updateHitbox();

            props.set(obj.name, sprite);
            add(sprite);
        }

        refresh();
    }

    public function create():Void {}
	public function createPost():Void {}

    public function refresh():Void {
        sort(Util.sortByZIndex);
    }

    public function getProp(prop:String):FlxSprite {
        return props.exists(prop) ? props.get(prop) : null;
    }

    public function onBeat(curBeat:Int):Void {}
    public function onStep(curStep:Int):Void {}
    public function onMeasure(curMeasure:Int):Void {}

    override function destroy():Void {
        super.destroy();

        gf.onAnimPlay.remove(onGFAnim);
        dad.onAnimPlay.remove(onDadAnim);
        bf.onAnimPlay.remove(onBFAnim);

        FlxG.camera.bgColor = prevBgColor;
    }
}