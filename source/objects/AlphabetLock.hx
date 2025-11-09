package objects;

class AlphabetLock extends Alphabet {
    var curFrame:Int = 0;
    var animTimer:Float = 0;
    var frameDuration:Float = 1 / 24;
    var lerpTimer:Float = 0;

    var locked:Bool = false;
    var selected:Bool = false;

    public function new(x:Int, y:Int, text:String, locked:Bool = false):Void {
        super(x, y, text);
        this.locked = locked;
    }
    
    public function triggerLock():Void {
        if (!locked) return;
        
        selected = true;

        if (!Data.flashingLights) {
            lerpTimer = 0;
            return;
        }

        animTimer = curFrame = 0;
        applyFrame();
    }
    
    private function applyFrame():Void {
        offset.x = -Constants.LOCK_ANIM_FRAMES[curFrame].x;
        color = Constants.LOCK_ANIM_FRAMES[curFrame].color;
    }
    
    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        
        if (!locked || !selected) return;
        
        if (!Data.flashingLights) {
            lerpTimer += elapsed;
            color = Util.lerpColor(0xFFFF0000, FlxColor.WHITE, Math.min(lerpTimer * 5, 1));
            return;
        }

        animTimer += elapsed;
            
        while (animTimer >= frameDuration && curFrame < Constants.LOCK_ANIM_FRAMES.length - 1) {
            animTimer -= frameDuration;
            curFrame++;
            applyFrame();
        }
    }
}