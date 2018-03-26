public class UmbrellaVerticalWave extends LXPattern {
  
  private float lowestUmbrella;
  private float highestUmbrella;
  private float umbrellaDelta;
  
  // half the distance away from the current position that is considered 'on'
  public final CompoundParameter waveSize =
    new CompoundParameter ("size", .05, 0, 1)
    .setDescription ("How wide the area turned on is.");
    
  public final CompoundParameter waveSpeed =
    new CompoundParameter ("speed", 0, 25000)
    .setDescription ("How fast the wave moves");
    
  // value determines the center of the area that is "on"
  public final SinLFO waveValue =
    new SinLFO (0, 1, waveSpeed);
  
  public UmbrellaVerticalWave (LX lx) {
    super(lx);
    
    addParameter (waveSize);
    addParameter (waveSpeed);
    startModulator(waveValue);
    
    lowestUmbrella = 0;
    highestUmbrella = 0;
    for (UIUmbrella u : umbrellaModel.umbrellas) {
      
      if (u.Position.y < lowestUmbrella)
        lowestUmbrella = u.Position.y;
        
      if (u.Position.y > highestUmbrella)
        highestUmbrella = u.Position.y;
    }
    
    umbrellaDelta = highestUmbrella - lowestUmbrella;
  }
  
  public void run (double deltaMs) {
    
    float waveValue = (float)this.waveValue.getValue();
    float waveWidth = (float)this.waveSize.getValue();
        
    for (UIUmbrella u : umbrellaModel.umbrellas) {
      float h = u.Position.y;
      float pct = (h - lowestUmbrella) / umbrellaDelta;
      
      float pctDist = constrain (1 - (abs(pct - waveValue) / waveWidth), 0, 1);
      
      u.PercentClosed = pctDist;
    }
  }
}
