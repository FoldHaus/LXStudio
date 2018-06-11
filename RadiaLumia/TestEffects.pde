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
