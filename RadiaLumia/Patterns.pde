int PercentToPositionSteps (double position)
{
    return RadiaNodeSpecialDatagram.MOTOR_DATA_MASK & (int) (Bloom.Umbrella.MaxSteps * position);
}

double PositionStepsToPercent (int positionSteps)
{
    // TODO(peter): Fill this out
    return 0;
}

public abstract class RadiaLumiaPattern extends LXModelPattern<Model> {
    public RadiaLumiaPattern(LX lx) {
        super(lx);
    }
    
    //NOTE(peter): umbrella position is in a range from (0, 1) inclusive
    public void setUmbrella(Bloom bloom, double position) {
        final int positionSteps = RadiaNodeSpecialDatagram.MOTOR_DATA_MASK & (int) (Bloom.Umbrella.MaxSteps * position);
        this.colors[bloom.umbrella.position.index] = 0xff000000 | positionSteps;
    }
    
    //NOTE(peter): pin spot brightness is in a range from (0, 255) inclusive
    public void setPinSpot (Bloom bloom, int brightness) {
        this.colors[bloom.spike.pinSpot.index] = LXColor.rgba(brightness, brightness, brightness, 255);
    }
}

// RadiaSolid

public class RadiaSolid extends RadiaLumiaPattern {
    
    // color parameters
    
    public final ColorParameter currentColor = 
        new ColorParameter("currentColor");
    
    public RadiaSolid (LX lx){
        super(lx);
        
        addParameter(currentColor);
        
    }
    
    public void run(double deltaMs){
        
        int c = currentColor.getColor();
        
        for (LXPoint light : model.leds) {
            colors[light.index] = c;
        }
        
    }
    
}

//rotateAroundBlooms
@LXCategory("Color")
public class Pinwheel extends RadiaLumiaPattern {
    
    public final CompoundParameter period = 
        new CompoundParameter ("delay", 1, 0, 10000);
    
    public final DiscreteParameter step =  
        new DiscreteParameter ("step", 1, 0, 60);
    
    protected int spokeCount = 0;
    protected double timeSinceLastHueChange = 0;
    protected int hueOffset = 0; 
    
    public Pinwheel (LX lx){
        super(lx); 
        
        addParameter(period);
        addParameter(step);
        
    }
    
    public void run (double deltaMs){
        
        timeSinceLastHueChange += deltaMs;
        
        if (timeSinceLastHueChange >= period.getValue()) {
            hueOffset = (hueOffset+step.getValuei())%360;
            timeSinceLastHueChange = 0;
        }
        
        for (Bloom b : model.blooms) { //loops through all blooms
            int hueCount = 0 + hueOffset; 
            for (Bloom.Spoke s : b.spokes){
                for (LXPoint p : s.points){
                    colors[p.index] = LXColor.hsb(hueCount, 100, 100);
                }
                
                hueCount = (hueCount + 60)%360;
                
            }
            
            
        }
    }
}

// Sparkle

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







// Static

public class Static extends RadiaLumiaPattern {
    public final CompoundParameter brightness = 
        new CompoundParameter ("Brightness", .1, 0,1)
        .setDescription("Set global brightness");
    
    public final CompoundParameter numPoints =  
        new CompoundParameter ("Points", 1, 0, 1000)
        .setDescription("Set number of sparkle points");
    
    public final DiscreteParameter maxDistance = 
        new DiscreteParameter ("Width", 1, 0, 100)
        .setDescription("Set distance of exapansion");
    
    public Static(LX lx) {
        super(lx);
        addParameter(this.brightness); 
        addParameter(this.numPoints);
        addParameter(this.maxDistance);
    }
    
    public void run(double deltaMs) {
        int curMaxValue = maxDistance.getValuei();
        double curBrightness = brightness.getValue();
        
        
        for (Bloom b : model.blooms) { //loops through all blooms
            
            for (int p = 0; p < numPoints.getValue(); p++) {
                
                int rI = (int)random((float)b.points.length);  
                
                int min = rI-curMaxValue; 
                if (min < 0) {
                    min = 0; 
                }
                
                int max = rI+curMaxValue;
                if (max >= b.points.length) {
                    max =  b.points.length-1;
                }
                
                for (int i=min; i<max; i++){
                    double distance; 
                    distance = abs(i-rI)/(float)curMaxValue;
                    colors[b.points[i].index] = LXColor.hsb(0,0,(int)(curBrightness*255*distance));     
                }
            }
        }
    }
}

public class BlossomOscillation extends RadiaLumiaPattern {
    
    // half the distance away from the current position that is considered 'on'
    public final CompoundParameter fillRadius =
        new CompoundParameter("rad", .05, 0, .5)
        .setDescription("How wide the area turned on is.");
    
    // value determines the center of the area that is "on"
    public final SinLFO oscillator =
        new SinLFO(0, 1, 7000);
    
    public BlossomOscillation(LX lx) {
        super(lx);
        addParameter(this.fillRadius);
        startModulator(this.oscillator);
    }
    
    public void run(double deltaMs) {
        // The base values for the center, and width of the "on" area
        float center = (float) this.oscillator.getValue();
        float fillRadius = (float) this.fillRadius.getValue();
        
        // Converting base values into bounds
        float minOn = center - fillRadius;
        float maxOn = center + fillRadius;
        
        // The spike represents the area from [.5, 1] so we translate the min/max values into this space and clip them
        // to the bounds of the spike region. For example, if minOn = .2 and maxOn = .6, then spikeMinOn = 0 and spikeMaxOn = .2
        float spikeMinOn = constrain((minOn - .5) * 2, 0, 1);
        float spikeMaxOn = constrain((maxOn - .5) * 2, 0, 1);
        
        // Same as the spike, except that the spokes represent the region [0, .5]
        float spokesMinOn = constrain((minOn * 2), 0, 1);
        float spokesMaxOn = constrain((maxOn * 2), 0, 1);
        
        for (Bloom bloom : model.blooms) {
            
            // This was just so we could give each blossom a different color. Actually doesn't look great as is. This could be done elsewhere
            float hue = 360 * ((float) (bloom.id + 1) / (float) (model.blooms.size()));
            
            // Set the spike pixels which should be "on"
            for (LXPoint spikePoint : bloom.spike.points) {
                // the pixels distance from the blossom center
                float dst = new LXVector(spikePoint.x, spikePoint.y, spikePoint.z).dist(bloom.center);
                // the percentage of the total distance this pixel is
                float pctDst = (dst/bloom.maxSpikeDistance);
                
                float onMask = 0;
                // if the pctDst is between the spike normalized bounds, turn the pixel on
                if (pctDst > spikeMinOn && pctDst < spikeMaxOn) {
                    onMask = 100;
                }
                
                // set the color
                colors[spikePoint.index] = LXColor.hsb(hue, 100, onMask);
            }
            
            // This operates exactly the same as the spike, except that we invert pctDst so that the light flows up the spokes, towards the center, 
            // then up the spike, smoothly.
            for (LXPoint spokePoint : bloom.spokePoints) {
                float dst = new LXVector(spokePoint.x, spokePoint.y, spokePoint.z).dist(bloom.center);
                float pctDst = 1 - dst/bloom.maxSpikeDistance;
                float onMask = 0;
                if (pctDst > spokesMinOn && pctDst < spokesMaxOn) {
                    onMask = 100;
                }
                
                colors[spokePoint.index] = LXColor.hsb(hue, 100, onMask);
            }
        }
    }
}

public class BloomPulse extends RadiaLumiaPattern {
    
    public final CompoundParameter oscillatorPeriod =
        new CompoundParameter("per", 0, 10000);
    
    public final CompoundParameter pulseSize =
        new CompoundParameter("siz", 0, 1);
    
    public final CompoundParameter pulsePos = 
        new CompoundParameter("pos", 0, 1);
    
    
    public BloomPulse(LX lx) {
        super(lx);
        addParameter(this.oscillatorPeriod);
        addParameter(this.pulseSize);
        addParameter(this.pulsePos);
    }
    
    public void run(double deltaMs) {
        
        float oscillatorValue = (float) this.pulsePos.getValue();
        float pulseSizeValue = (float) this.pulseSize.getValue();
        
        
        for (Bloom bloom : model.blooms) {
            // Spike
            for (LXPoint spike : bloom.spike.points) {
                float percent = 1 - new LXVector(spike.x, spike.y, spike.z).dist(bloom.center) / bloom.maxSpikeDistance;
                percent = percent + oscillatorValue;
                
                float bright = round(sin(percent / pulseSizeValue)) * 100;
                
                colors[spike.index] = LXColor.hsb(360, 100, bright); //LXColor.multiply(colors[spike.index], LXColor.hsb(256, 256, bright));
            }
            
            for (LXPoint spoke : bloom.spokePoints) {
                float percent = new LXVector(spoke.x, spoke.y, spoke.z).dist(bloom.center) / bloom.maxSpokesDistance;
                percent = (percent * .5) + oscillatorValue;
                
                float bright = round(sin(percent / pulseSizeValue)) * 100;
                
                colors[spoke.index] = LXColor.hsb(360, 0, bright);
            }
        }
    }
}