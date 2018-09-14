@LXCategory("Pinspots")
public class PinspotTwinkle extends RadiaLumiaPattern {
    
    public final float MAX_SPEED_VALUE = 10000;
    
    public final CompoundParameter speed =
        new CompoundParameter("spd", 1, 0, MAX_SPEED_VALUE);
    
    public final BooleanParameter sinOscillation =
        new BooleanParameter("sin");
        
    public final CompoundParameter P_MaxBrightness =
        new CompoundParameter("brightness", 0, 0, 255);
    
    public float[] bloomPinspotOnTime;
    
    public PinspotTwinkle (LX lx) {
        super(lx);
        addParameter(speed);
        addParameter(sinOscillation);
        addParameter(P_MaxBrightness);
        
        bloomPinspotOnTime = new float[42];
        
        for (int i = 0; i < 42; i++) {
            bloomPinspotOnTime[i] = random(0, MAX_SPEED_VALUE);
        }
    }
    
    public void run (double deltaMs) {
        boolean _useSin = sinOscillation.getValueb();
        double _speed = speed.getValue();
        double _brightness = 0;
        double _maxBrightness = P_MaxBrightness.getValue();
        
        for (Bloom b : model.blooms) {
            
            bloomPinspotOnTime[b.id] += deltaMs;
            
            if (bloomPinspotOnTime[b.id] >= _speed) {
                _brightness = _speed - (double)bloomPinspotOnTime[b.id];
            } else {
                _brightness = (double)bloomPinspotOnTime[b.id];
            }
            
            _brightness /= _speed;
            if (_useSin)
                _brightness = .5 + .5 * (double)sin(3.14f * (float)_brightness);
            
            setPinSpot(b, (int)(_brightness * _maxBrightness)); 
        }
    }
}
