// UmbrellaUniversalState
/*
  Sets all umbrellas to the same state, as defined by the CompoundParameter
  openClosedState
*/
public class UmbrellaUniversalState extends BaseUmbrellaPattern {

  public final CompoundParameter openClosedState =
    new CompoundParameter ("open", 0, 0, 1)
    .setDescription ("How open are the umbrellas");

  public UmbrellaUniversalState (LX lx) {
    super(lx);

    addParameter (this.openClosedState);
  }

  public void run (double deltaMs) {
    double newPercentClosed = 1 - this.openClosedState.getValue();
    
    for (GeodesicModel3D.Bloom b : structureModel.radiaLumia.blooms) {
      SetUmbrellaPercentClosed(b.umbrella, newPercentClosed);
    }
  }
}

// UmbrellaVerticalWave
/*
  Visualizes a sin wave on the umbrellas.
  Oscilation is defined by waveValue
  Frequency is waveSize, period is waveSeed
 */
public class UmbrellaVerticalWave extends BaseUmbrellaPattern {

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
    
    for (GeodesicModel3D.Bloom b : structureModel.radiaLumia.blooms) {

      if (b.bloomCenter.y < lowestUmbrella)
        lowestUmbrella = b.bloomCenter.y;

      if (b.bloomCenter.y > highestUmbrella)
        highestUmbrella = b.bloomCenter.y;
    }

    umbrellaDelta = highestUmbrella - lowestUmbrella;
  }

  public void run (double deltaMs) {

    float waveValue = (float)this.waveValue.getValue();
    float waveWidth = (float)this.waveSize.getValue();

    for (GeodesicModel3D.Bloom b : structureModel.radiaLumia.blooms) {
      float h = b.bloomCenter.y;
      float pct = (h - lowestUmbrella) / umbrellaDelta;

      float pctDist = constrain ((abs(pct - waveValue) / waveWidth), 0, 1);

      SetUmbrellaPercentClosed(b.umbrella, pctDist);
    }
  }
}
