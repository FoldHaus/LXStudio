public abstract class RadiaLumiaPattern extends LXModelPattern<Model> {
  public RadiaLumiaPattern(LX lx) {
    super(lx);
  }
}

public class BlossomOscillation extends RadiaLumiaPattern {

  // half the distance away from the current position that is considered 'on'
  public final CompoundParameter fillRadius =
    new CompoundParameter ("rad", .05, 0, .5)
    .setDescription ("How wide the area turned on is.");
  
  // value determines the center of the area that is "on"
  public final SinLFO oscillator =
    new SinLFO (0, 1, 7000);
    
  public BlossomOscillation (LX lx) {
    super(lx);
    
    addParameter (fillRadius);
    startModulator(oscillator);
  }
  
  public void run (double deltaMs) {
    // The base values for the center, and width of the "on" area
    float center = (float)this.oscillator.getValue();
    float fillRadius = (float)this.fillRadius.getValue();
    
    // Converting base values into bounds
    float minOn = center - fillRadius;
    float maxOn = center + fillRadius;
    
    // The spike represents the area from [.5, 1] so we translate the min/max values into this space and clip them
    // to the bounds of the spike region. For example, if minOn = .2 and maxOn = .6, then spikeMinOn = 0 and spikeMaxOn = .2
    float spikeMinOn = constrain ((minOn - .5) * 2, 0, 1);
    float spikeMaxOn = constrain ((maxOn - .5) * 2, 0, 1);
    
    // Same as the spike, except that the spokes represent the region [0, .5]
    float spokesMinOn = constrain ((minOn * 2), 0, 1);
    float spokesMaxOn = constrain ((maxOn * 2), 0, 1);
    
    // This was just so we could give each blossom a different color. Actually doesn't look great as is. This could be done elsewhere
    int bloomNumber = 0;
    
    for (Bloom bloom : model.blooms) {
    

      bloomNumber += 1;
      float hue = 360 * ((float)bloomNumber / (float)(model.blooms.size()));
      
      // Set the spike pixels which should be "on"
      for (LXPoint spikePoint : bloom.spike.getPoints()) {
        // the pixels distance from the blossom center
        float dst = new LXVector(spikePoint.x, spikePoint.y, spikePoint.z).dist(bloom.center);
        // the percentage of the total distance this pixel is
        float pctDst = (dst/bloom.maxSpikeDistance);
        
        float onMask = 0;
        // if the pctDst is between the spike normalized bounds, turn the pixel on
        if (pctDst > spikeMinOn && pctDst < spikeMaxOn)
          onMask = 100;

        // set the color
        colors[spikePoint.index] = LXColor.hsb(hue, 100, onMask);
      }
      
      // This operates exactly the same as the spike, except that we invert pctDst so that the light flows up the spokes, towards the center, 
      // then up the spike, smoothly.
      for (LXPoint spokePoint : bloom.spokePoints) {
        float dst = new LXVector(spokePoint.x, spokePoint.y, spokePoint.z).dist(bloom.center);
        float pctDst = 1 - dst/bloom.maxSpikeDistance;
        float onMask = 0;
        if (pctDst > spokesMinOn && pctDst < spokesMaxOn)
          onMask = 100;
        
        colors[spokePoint.index] = LXColor.hsb(hue, 100, onMask);
      }
    }
  }
}

public class BloomPulse extends RadiaLumiaPattern {

  public final CompoundParameter oscillatorPeriod =
    new CompoundParameter ("per", 0, 10000);

  public final CompoundParameter pulseSize =
    new CompoundParameter ("siz", 0, 1);
  
  public final CompoundParameter pulsePos = 
    new CompoundParameter ("pos", 0, 1);


  public BloomPulse (LX lx) {
    super(lx);

    addParameter(oscillatorPeriod);
    addParameter(pulseSize);
    addParameter(pulsePos);
  }

  public void run (double deltaMs) {
    
    float oscillatorValue = (float)pulsePos.getValue();
    float pulseSizeValue = (float)pulseSize.getValue();
   
   
    for (Bloom bloom : model.blooms) {
      // Spike
      for (LXPoint spike : bloom.spike.getPoints()) {
        float percent = 1 - new LXVector(spike.x, spike.y, spike.z).dist(bloom.center) / bloom.maxSpikeDistance;
        percent = percent + oscillatorValue;
        
        float bright = round(sin(percent / pulseSizeValue)) * 100;
        
        colors[spike.index] = LXColor.hsb(360, 100, (int)bright); //LXColor.multiply(colors[spike.index], LXColor.hsb(256, 256, bright));
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
