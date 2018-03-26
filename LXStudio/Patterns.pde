public class Test extends LXPattern {
  
  public final CompoundParameter fillMin =
    new CompoundParameter ("min", 0, 0, 0);
  
  public final CompoundParameter fillMax =
    new CompoundParameter ("max", .5, 0, 1);
    
  public final CompoundParameter fillRadius =
    new CompoundParameter ("rad", .05, 0, .5);
    
  public final SinLFO modulator =
    new SinLFO (0, 1, 7000);
    
  public Test (LX lx) {
    super(lx);
    addParameter(fillMin);
    addParameter(fillMax);
    
    addParameter (fillRadius);
    startModulator(modulator);
  }
  
  public void run (double deltaMs) {
    float mod = (float)this.modulator.getValue();
    float fillRadius = (float)this.fillRadius.getValue();
    
    float minOn = mod - fillRadius;
    float maxOn = mod + fillRadius;
    //float minOn = (float)this.fillMin.getValue();
    //float maxOn = (float)this.fillMax.getValue();
    
    float spikeMinOn = constrain ((minOn - .5) * 2, 0, 1);
    float spikeMaxOn = constrain ((maxOn - .5) * 2, 0, 1);
    
    float spokesMinOn = constrain ((minOn * 2), 0, 1);
    float spokesMaxOn = constrain ((maxOn * 2), 0, 1);
    
    int bloomNumber = 0;
    
    for (GeodesicModel3D.Bloom bloom : structureModel.radiaLumia.blooms) {
      
      bloomNumber += 1;
      float hue = 360 * ((float)bloomNumber / (float)(structureModel.radiaLumia.blooms.length));
      
      for (LXPoint spikePoint : bloom.spike.getPoints()) {
        float dst = new LXVector(spikePoint.x, spikePoint.y, spikePoint.z).dist(bloom.bloomCenter);
        float pctDst = (dst/bloom.maxSpikeDistance);
        float onMask = 0;
        if (pctDst > spikeMinOn && pctDst < spikeMaxOn)
          onMask = 100;

        colors[spikePoint.index] = LXColor.hsb(hue, 100, onMask);
      }
      
      for (LXPoint spokePoint : bloom.spokes.getPoints ()) {
        float dst = new LXVector(spokePoint.x, spokePoint.y, spokePoint.z).dist(bloom.bloomCenter);
        float pctDst = 1 - dst/bloom.maxSpikeDistance;
        float onMask = 0;
        if (pctDst > spokesMinOn && pctDst < spokesMaxOn)
          onMask = 100;
        
        colors[spokePoint.index] = LXColor.hsb(hue, 100, onMask);
      }
    }
  }
}
