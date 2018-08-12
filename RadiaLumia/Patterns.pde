public abstract class RadiaLumiaPattern extends LXModelPattern<Model> {
    public RadiaLumiaPattern(LX lx) {
        super(lx);
    }
    
    //NOTE(peter): umbrella position is in a range from (0, 1) inclusive
    public void setUmbrella(Bloom bloom, double position) {
        double ClampedPosition = clamp(position, 0, 1);
        final int positionSteps = RadiaNodeSpecialDatagram.MOTOR_DATA_MASK & (int) (bloom.umbrella.MaxPulses * ClampedPosition);
        this.colors[bloom.umbrella.position.index] = 0xff000000 | positionSteps;
    }
    
    //NOTE(peter): pin spot brightness is in a range from (0, 255) inclusive
    public void setPinSpot (Bloom bloom, int brightness) {
        this.colors[bloom.spike.pinSpot.index] = LXColor.rgba(brightness, brightness, brightness, 255);
    }
}

// Static
@LXCategory("Texture")
public class Static extends RadiaLumiaPattern 
{
    public final CompoundParameter brightness = 
        new CompoundParameter ("Brightness", .1, 0,1)
        .setDescription("Set global brightness");
    
    public final CompoundParameter numPoints =  
        new CompoundParameter ("Points", 1, 0, 1000)
        .setDescription("Set number of sparkle points");
    
    public final DiscreteParameter maxDistance = 
        new DiscreteParameter ("Width", 1, 0, 100)
        .setDescription("Set distance of exapansion");
    
    public Static(LX lx) 
    {
        super(lx);
        addParameter(this.brightness); 
        addParameter(this.numPoints);
        addParameter(this.maxDistance);
    }
    
    public void run(double deltaMs) 
    {
        int curMaxValue = maxDistance.getValuei();
        double curBrightness = brightness.getValue();
        
        
        for (Bloom b : model.blooms) 
        { //loops through all blooms
            
            for (int p = 0; p < numPoints.getValue(); p++) 
            {
                
                int rI = (int)random((float)b.points.length);  
                
                int min = rI-curMaxValue; 
                if (min < 0) 
                {
                    min = 0; 
                }
                
                int max = rI+curMaxValue;
                if (max >= b.points.length) 
                {
                    max =  b.points.length-1;
                }
                
                for (int i=min; i<max; i++)
                {
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
