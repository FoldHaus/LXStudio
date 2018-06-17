@LXCategory("Test")
public class TestLedStrips extends RadiaLumiaPattern {
    
  public TestLedStrips(LX lx) {
    super(lx);
  }
  
  public void run(double deltaMs) {
        
    int spikeAColor = LXColor.rgb(255, 0, 0);
    int spikeBColor = LXColor.rgb(255, 128, 0);
    
    int spokeOutColor = LXColor.rgb(0, 255, 0);
    int spokeInColor = LXColor.rgb(0, 0, 255);
    
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
