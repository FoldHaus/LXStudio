@LXCategory("Test")
public class TestLedStrips extends RadiaLumiaPattern {
    
  public final DiscreteParameter spokeBrightness =
    new DiscreteParameter("spi", 100, 0, 100);
  
  public final DiscreteParameter spikeBrightness =
    new DiscreteParameter("spo", 100, 0, 100);
  
  public final DiscreteParameter pinSpotBrightness =
    new DiscreteParameter("pin", 0, 0, 256);

  public final DiscreteParameter heartBrightness =
    new DiscreteParameter("hrt", 100, 0, 100);

  public final CompoundParameter umbrellaPosition =
    new CompoundParameter ("um", 0, 0, 1);
  
  public final BooleanParameter printDebug =
    new BooleanParameter("print");
  
  
  public TestLedStrips(LX lx) {
    super(lx);
    addParameter(spokeBrightness);
    addParameter(spikeBrightness);
    addParameter(pinSpotBrightness);
    addParameter(heartBrightness);
    addParameter(umbrellaPosition);
    addParameter(printDebug);
  }
  
  public void run(double deltaMs) {
        
    int spikeAColor = LXColor.hsb(0, 100, spikeBrightness.getValuei());
    int spikeBColor = LXColor.hsb(64, 100, spikeBrightness.getValuei());
    
    int spokeOutColor = LXColor.hsb(128, 100, spokeBrightness.getValuei());
    int spokeInColor = LXColor.hsb(192, 100, spokeBrightness.getValuei());
    
    int pinSpotColor = pinSpotBrightness.getValuei();
    
    int heartColor = LXColor.hsb(320, 100, heartBrightness.getValue());
    
    double umbrellaPos = umbrellaPosition.getValue();

    boolean bloom_debug = !printDebug.getValueb();
    
    for (Bloom bloom : model.blooms) {
      
      for (LXPoint spikeAPoint : bloom.spike.stripA) {
        colors[spikeAPoint.index] = spikeAColor;
      }
      for (LXPoint spikeBPoint : bloom.spike.stripB) {
        colors[spikeBPoint.index] = spikeBColor;
      }
      
      for (Bloom.Spoke spoke : bloom.spokes) {
        for (LXPoint inPoint : spoke.inPoints) {
          colors[inPoint.index] = spokeInColor;
        }
        for (LXPoint outPoint : spoke.outPoints) {
          colors[outPoint.index] = spokeOutColor;
        }
      }
      
      setPinSpot(bloom, pinSpotColor);
      setUmbrella(bloom, umbrellaPos);

      if (!bloom_debug) {
        println("Pinspot Index:", bloom.spike.pinSpot.index);
        println("Pinspot Color:", colors[bloom.spike.pinSpot.index]);
        println("Pinspot Pos:", bloom.spike.pinSpot.x, bloom.spike.pinSpot.y, bloom.spike.pinSpot.z);
        bloom_debug = true;
      }
    }
    
    for (LXPoint p : model.heart.points) {
      colors[p.index] = heartColor;
    }
  }
}

@LXCategory ("Test")
public class IdentifyBloom extends RadiaLumiaPattern {
  
  public final DiscreteParameter bloomId =
    new DiscreteParameter("id", 0, 0, 42)
    .setDescription("The id of the bloom to indicate");
  
  public final BooleanParameter useLights =
    new BooleanParameter("lit")
    .setDescription("Use lights to indicate the desired bloom");

  public final BooleanParameter useUmbrellas =
    new BooleanParameter("umb")
    .setDescription("Use the umbrellas to indicate the desired bloom");
  
  public final ColorParameter lightColor =
    new ColorParameter("col")
    .setDescription("The light to illuminate the selected umbrella with");
  
  public IdentifyBloom(LX lx) {
    super(lx);
    addParameter(bloomId);
    addParameter(useLights);
    addParameter(useUmbrellas);
    addParameter(lightColor);
  }

  public void run (double deltaMs) {
    boolean lit = useLights.getValueb();
    boolean umbrellas = useLights.getValueb();
    int col = lightColor.getColor();
    int id = bloomId.getValuei();

    int curr_col = 0;
    double curr_pos = 0;
    
    for (Bloom bloom : model.blooms) {
      if (bloom.id == id && lit) {
        curr_col = col;
      }else{
        curr_col = LXColor.BLACK;
      }
      
      if (bloom.id == id && umbrellas) {
        curr_pos = 1.0;
      }else{
        curr_pos = 0.0;
      }
      
      
      for (LXPoint light : bloom.leds) {        
        colors[light.index] = curr_col;
      }
    
      setUmbrella(bloom, curr_pos);
    }
  }
}
