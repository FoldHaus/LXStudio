public abstract class BaseUmbrellaPattern extends LXPattern {

  private LXChannel channel;
  
  private boolean isTransitioningIn;
  private boolean isActive;

  public BaseUmbrellaPattern (LX lx) {
    super(lx);
    channel = this.getChannel();
    
    if (umbrellaUpdater == null) {
      lx.engine.masterChannel.addEffect(new SingletonUmbrellaUpdater(lx));
    }
    
    isTransitioningIn = false;
    isActive = false;
  }
  
  @Override
  public void onTransitionStart() {
    isTransitioningIn = true;
  }
  
  @Override
  public void onTransitionEnd() {
    isTransitioningIn = false;
  }
  
  @Override
  public void onActive () {
    isActive = true;
  }
  
  @Override
  public void onInactive () {
    isActive = false;
  }
  
  public double getWeight (boolean printWeightProgress) {
     double weight = channel.fader.getNormalized();
     double progress = channel.getTransitionProgress();
      
     if (isTransitioningIn && !(progress > 0)) { 
       weight = 0;
     } else if (progress > 0) {
       if (!isTransitioningIn && progress < .998) {
         weight *= 1 - progress;
       }else if (isTransitioningIn){
         weight *= progress;
       }
     }
      
     if (printWeightProgress)
       println (getIndex() + " : " + progress + " : " + weight);
      
     return weight;
  }
  
  public void SetUmbrellaPercentClosed (GeodesicModel3D.Umbrella u, double pctClosed) {
    if (channel == null)
      channel = this.getChannel();

    double weight = getWeight(false);

    u.RequestPercentClosed(pctClosed, weight);
  }
}

public class SingletonUmbrellaUpdater extends LXEffect {
  public SingletonUmbrellaUpdater (LX lx) {
   super(lx);
   umbrellaUpdater = this;
   this.enable();
  }
  
  public void run (double deltaMs, double enabledAmount) {
    for (GeodesicModel3D.Bloom b : structureModel.radiaLumia.blooms) {
      b.umbrella.ApplyPercentageRequests();
    }
  }
}

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

      float pctDist = constrain (1 - (abs(pct - waveValue) / waveWidth), 0, 1);

      SetUmbrellaPercentClosed(b.umbrella, pctDist);
    }
  }
}
