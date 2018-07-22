
@LXCategory("Masks")
public class BloomPulse extends RadiaLumiaPattern {
    
    public final CompoundParameter P_OscillatorPeriod =
        new CompoundParameter("Period", 0, 10000);
    
    public final CompoundParameter P_PulseSize =
        new CompoundParameter("Size", 0, 1);
    
    public final SawLFO P_Offset =
        new SawLFO(0, TWO_PI, P_OscillatorPeriod);
    
    public BloomPulse(LX lx)
    {
        super(lx);
        
        addParameter(P_OscillatorPeriod);
        addParameter(P_PulseSize);
        
        startModulator(P_Offset);
    }
    
    public void run(double deltaMs)
    {
        
        float OscillatorValue = (float) this.P_Offset.getValue();
        float PulseSize = (float) this.P_PulseSize.getValue();
        
        LXVector PointVector;
        float Percent;
        float Offset;
        float Brightness;
        
        for (Bloom bloom : model.blooms)
        {
            // Spike
            for (LXPoint spike : bloom.spike.leds) 
            {
                PointVector = LXPointToVector(spike);
                Percent = 1 - (PointVector.dist(bloom.center) / bloom.maxSpikeDistance);
                Offset = (Percent + OscillatorValue) % TWO_PI;
                
                Brightness = constrain(sin(Offset / PulseSize) * 100, 0, 100);
                
                colors[spike.index] = LXColor.hsb(360, 0, Brightness);
            }
            
            for (LXPoint spoke : bloom.spokePoints) 
            {
                PointVector = LXPointToVector(spoke);
                Percent = PointVector.dist(bloom.center) / bloom.maxSpokesDistance;
                Offset = ((Percent * .5) + OscillatorValue) % TWO_PI;
                
                Brightness = constrain((sin(Offset / PulseSize) * 100), 0, 100);
                
                colors[spoke.index] = LXColor.hsb(360, 0, Brightness);
            }
        }
    }
}


// Sparkle
@LXCategory("Masks")
public class Sparkle extends RadiaLumiaPattern {
    
    // Parameters
    
    public final DiscreteParameter numFeatures = 
        new DiscreteParameter("num", 1, 0, 250);
    
    public final CompoundParameter feature_lifetime =
        new CompoundParameter("life", 1, 0, 30000);
    
    public final CompoundParameter  feature_size=
        new CompoundParameter("size", 1, 0, 100);
    
    public final CompoundParameter feature_brightness =
        new CompoundParameter("bri", 1, 0, 1);
    // Instance Variables
    
    class FeaturePoint {
        public double currLifetime;
        public double maxLifetime;
        public LXVector position;
        
        public FeaturePoint(
            double lifetime,
            LXVector position
            ){
            this.maxLifetime = lifetime;
            this.position = position;
        }
    }
    
    List<FeaturePoint> feature_points;
    
    public Sparkle (LX lx){
        super(lx);
        
        addParameter(numFeatures);
        addParameter(feature_lifetime);
        addParameter(feature_size);
        addParameter(feature_brightness);
        
        feature_points = new ArrayList<FeaturePoint>();
    }
    
    public void run(double deltaMs){
        
        if (numFeatures.getValuei() > feature_points.size()) {
            CacheFeaturePoints();
        }
        
        UpdateFeaturePoints(deltaMs);
        UpdateLeds();
    }
    
    public void CacheFeaturePoints() {
        
        // Create the feature points
        // How many?
        // Lifetime, max size, max brightness
        
        LXVector randPoint;
        
        for (int i = 0; i < numFeatures.getValuei(); i++) {
            feature_points.add(CreateNewFeaturePoint());
        }
        
        println(feature_points.size());
    }
    
    public FeaturePoint CreateNewFeaturePoint(){
        LXVector randPoint = LXPointToVector(
            model.leds.get(
            (int)(random(1) * model.leds.size())));
        
        double lifetime = feature_lifetime.getValue();
        lifetime += random((float)feature_lifetime.getValue()) - (.5 * feature_lifetime.getValue());
        
        FeaturePoint fpoint = new FeaturePoint(
            lifetime,
            randPoint
            );
        
        return fpoint;
    }
    
    public void UpdateFeaturePoints(double deltaMs) {
        
        // Update all feature points
        // 1. Update lifetime
        // 2. Update size based on lifetime
        // 3. Update brightness based on lifetime
        
        for (int f = 0; f < numFeatures.getValuei(); f++) {
            feature_points.get(f).currLifetime += deltaMs;
            
            if (feature_points.get(f).currLifetime >= feature_points.get(f).maxLifetime) {
                feature_points.set(f, CreateNewFeaturePoint());
            }
        }
        
    }
    
    public void UpdateLeds() {
        
        // Update all leds
        // 1. Check distance to every feature point
        // 2. Update brightness based on closest feature point
        
        LXVector led_point;
        
        int closest_feature_index = -1;
        double closest_feature_distance = 10000;
        
        double maxDistance = feature_size.getValue();
        double maxBrightness = feature_brightness.getValue();
        
        for(LXPoint p : model.leds) {
            
            // Reset
            closest_feature_index = -1;
            closest_feature_distance = 10000;
            
            led_point = LXPointToVector(p);
            
            // Get closest feature point
            for (int f = 0; f < numFeatures.getValuei(); f++) {
                
                double distance = led_point.dist(feature_points.get(f).position);
                
                if (distance < closest_feature_distance) {
                    closest_feature_distance = distance;
                    closest_feature_index = f;
                }
            }
            
            double feature_decay = feature_points.get(closest_feature_index).currLifetime / feature_points.get(closest_feature_index).maxLifetime;
            feature_decay = 6.28  * (1.0 - feature_decay);
            feature_decay = .5 + (.5 * sin((float)feature_decay));
            
            double curr_distance = closest_feature_distance / maxDistance;
            curr_distance = clamp(curr_distance, 0, 1);
            curr_distance = 1 - curr_distance;
            
            double led_brightness = feature_decay * curr_distance;
            led_brightness *= maxBrightness;
            
            if (closest_feature_index == -1)
                led_brightness = 0;
            
            colors[p.index] = LXColor.hsb(0, 0, (int)(led_brightness * 100));
        }
    }
    
}
