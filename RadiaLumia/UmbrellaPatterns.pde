// Sets all umbrellas to a universal position
@LXCategory("Umbrella")
public class UmbrellaUniversalState extends RadiaLumiaPattern {

  // Position of the umbrellas
  public final CompoundParameter position =
    new CompoundParameter("Position", 0)
    .setDescription("How extended are the umbrellas");

  public UmbrellaUniversalState(LX lx) {
    super(lx);
    addParameter("position", this.position);
  }

  public void run (double deltaMs) {
    double position = this.position.getValue();
    for (Bloom b : model.blooms) {
      setUmbrella(b, position);
    }
  }
}

// UmbrellaVerticalWave
/*
  Visualizes a sin wave on the umbrellas.
  Oscilation is defined by waveValue
  Frequency is waveSize, period is waveSeed
 */
@LXCategory("Umbrella")
public class UmbrellaVerticalWave extends RadiaLumiaPattern {

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
    
    for (Bloom b : model.blooms) {

      if (b.center.y < lowestUmbrella)
        lowestUmbrella = b.center.y;

      if (b.center.y > highestUmbrella)
        highestUmbrella = b.center.y;
    }

    umbrellaDelta = highestUmbrella - lowestUmbrella;
  }

  public void run (double deltaMs) {

    float waveValue = (float)this.waveValue.getValue();
    float waveWidth = (float)this.waveSize.getValue();

    for (Bloom b : model.blooms) {
      float h = b.center.y;
      float pct = (h - lowestUmbrella) / umbrellaDelta;

      float pctDist = constrain ((abs(pct - waveValue) / waveWidth), 0, 1);

      setUmbrella(b, pctDist);
    }
  }
}
