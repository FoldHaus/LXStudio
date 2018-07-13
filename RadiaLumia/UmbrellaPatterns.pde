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

// UmbrellaTest1
/*
  Umbrellas are 100% open at bottom and closed at top
  
  Increase complexity w/ selectable start top / bottom. Can make 100% a selectable spot (in middle). 
  */ 

@LXCategory("Umbrella")
public class yPositionOpen extends RadiaLumiaPattern {  
    private float lowestUmbrella;
    private float highestUmbrella;
    private float umbrellaDelta;
    
    public final CompoundParameter yPositionOpen =
    new CompoundParameter ("yPosOpen", 0, 1)
    .setDescription ("What percent verticle in y direction");
    
    public final CompoundParameter ySquash =
    new CompoundParameter ("ySquash", 0.01, 1)
    .setDescription ("How large of a gradient is created");
    
    public yPositionOpen (LX lx) {
    super(lx);
      addParameter (yPositionOpen);
      addParameter (ySquash);
      
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
      
      float yPositionOpen = (float)this.yPositionOpen.getValue();
      float ySquash = (float)this.ySquash.getValue(); 
      
      for (Bloom b : model.blooms) {
        float centerPoint = b.center.y;
        float pct = (centerPoint - lowestUmbrella) / umbrellaDelta;
        float yPosDistance = (1-abs(pct - yPositionOpen)); //inverse gives out 1 at ypos
        float yPosPCT = 1-yPosDistance/ySquash; 
        setUmbrella(b, constrain(yPosPCT, 0, 1));
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

@LXCategory("Umbrella")
public class NoahsPattern extends RadiaLumiaPattern {

  // Position of the umbrellas
  public final CompoundParameter half_A =
    new CompoundParameter("A", 0)
    .setDescription("How extended are the umbrellas");

  public final CompoundParameter half_B = 
    new CompoundParameter("B", 0);
  
  public NoahsPattern(LX lx) {
    super(lx);
    addParameter(this.half_A);
    addParameter(this.half_B);
  }

  public void run (double deltaMs) {
    double position_A = this.half_A.getValue();
    double position_B = this.half_B.getValue();
    
    for (Bloom b : model.blooms) {
      if (b.center.x < 0) {
        setUmbrella(b, position_A);
      }else{
        setUmbrella(b, position_B);
      }
    }
  }
}