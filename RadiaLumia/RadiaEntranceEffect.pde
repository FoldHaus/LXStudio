public static int ENTRANCE_BLOOM_ONE = 3;
public static int ENTRANCE_BLOOM_TWO = 28;
public static int ENTRANCE_BLOOM_THREE = 27;

public static int CONTROL_BLOOM_ONE_TWO = 29;
public static int CONTROL_BLOOM_TWO_THREE = 38;
public static int CONTROL_BLOOM_THREE_ONE = 21;

// The effect for controlling the entrance to the Radia Lumia. 
// TODO(???): Get this to be controlled by OSC
// TODO(???): Add a delay after reachign full open, during which the OSC signal can be dropped and the entrance remains open
// TODO(???): Add a global light/umbrella effect that can signal someone entering the structure
public class RadiaEntranceEffect extends BaseUmbrellaPattern {

  public final CompoundParameter bloomOneState =
    new CompoundParameter ("b1s", 0, 0, 20)
    .setDescription ("How open bloom one is");
    
  public final CompoundParameter bloomTwoState =
    new CompoundParameter ("b2s", 0, 0, 20)
    .setDescription ("How open bloom one is");
    
  public final CompoundParameter bloomThreeState =
    new CompoundParameter ("b3s", 0, 0, 20)
    .setDescription ("How open bloom one is");
    
  public RadiaEntranceEffect (LX lx) {
    super(lx);

    addParameter(bloomOneState);
    addParameter(bloomTwoState);
    addParameter(bloomThreeState);
  }

  public void run (double deltaMs) {
    
    // Get the origins (bloom positions)
    // TODO(peter): Can this be done once, in the constructor?
    Bloom ctrl_bloomOneTwo = model.blooms.get(CONTROL_BLOOM_ONE_TWO);
    Bloom ctrl_bloomTwoThree = model.blooms.get(CONTROL_BLOOM_TWO_THREE);
    Bloom ctrl_bloomThreeOne = model.blooms.get(CONTROL_BLOOM_THREE_ONE);
    
    // Get the entrance blooms
    Bloom bloomOne = model.blooms.get(ENTRANCE_BLOOM_ONE);
    Bloom bloomTwo = model.blooms.get(ENTRANCE_BLOOM_TWO);
    Bloom bloomThree = model.blooms.get(ENTRANCE_BLOOM_THREE);
    
    // Light up blooms being pulled
    double c12_intensity = bloomOneState.getValue();
    double c23_intensity = bloomTwoState.getValue();
    double c31_intensity = bloomThreeState.getValue();
    
    for (LXPoint p : ctrl_bloomOneTwo.leds) {
      colors[p.index] = LXColor.hsb(200, 100, (float)(c12_intensity * 5));
    }
    
    for (LXPoint p : ctrl_bloomTwoThree.leds) {
      colors[p.index] = LXColor.hsb(200, 100, (float)(c23_intensity * 5));
    }
    
    for (LXPoint p : ctrl_bloomThreeOne.leds) {
      colors[p.index] = LXColor.hsb(200, 100, (float)(c31_intensity * 5));
    }
    
    
    
    // TODO(peter): do this in an array
    double c12_radius = c12_intensity * FEET;
    double c23_radius = c23_intensity * FEET;
    double c31_radius = c31_intensity * FEET;
    
    // Inside Circle Mask
    double bloomOne_InCircleMask = 1 - max( // Am I in either c12, c23, or c31
      constrain((float)(c12_radius - bloomOne.center.dist(ctrl_bloomOneTwo.center)), 0, 1), // Am I in c12_radius?
      max( // Am i in either c23_radius or c31_radius
        constrain((float)(c23_radius - bloomOne.center.dist(ctrl_bloomTwoThree.center)), 0, 1), // Am I in c23_radius?
        constrain((float)(c31_radius - bloomOne.center.dist(ctrl_bloomThreeOne.center)), 0, 1))); // Am I in c31_radius?
        
     double bloomTwo_InCircleMask = 1 - max( // Am I in either c12, c23, or c31
      constrain((float)(c12_radius - bloomTwo.center.dist(ctrl_bloomOneTwo.center)), 0, 1), // Am I in c12_radius?
      max( // Am i in either c23_radius or c31_radius
        constrain((float)(c23_radius - bloomTwo.center.dist(ctrl_bloomTwoThree.center)), 0, 1), // Am I in c23_radius?
        constrain((float)(c31_radius - bloomTwo.center.dist(ctrl_bloomThreeOne.center)), 0, 1))); // Am I in c31_radius?
     
      double bloomThree_InCircleMask = 1 - max( // Am I in either c12, c23, or c31
      constrain((float)(c12_radius - bloomThree.center.dist(ctrl_bloomOneTwo.center)), 0, 1), // Am I in c12_radius?
      max( // Am i in either c23_radius or c31_radius
        constrain((float)(c23_radius - bloomThree.center.dist(ctrl_bloomTwoThree.center)), 0, 1), // Am I in c23_radius?
        constrain((float)(c31_radius - bloomThree.center.dist(ctrl_bloomThreeOne.center)), 0, 1))); // Am I in c31_radius?
    
    // Generate Percent Closed
    SetUmbrellaPercentClosed(bloomOne.umbrella, bloomOne_InCircleMask);
    SetUmbrellaPercentClosed(bloomTwo.umbrella, bloomTwo_InCircleMask);
    SetUmbrellaPercentClosed(bloomThree.umbrella, bloomThree_InCircleMask);
    
    // Simulate Open-Closing of Control Blooms
    SetUmbrellaPercentClosed(ctrl_bloomOneTwo.umbrella, 1 - (c12_intensity/20));
    SetUmbrellaPercentClosed(ctrl_bloomTwoThree.umbrella, 1 - (c23_intensity/20));
    SetUmbrellaPercentClosed(ctrl_bloomThreeOne.umbrella, 1 - (c31_intensity/20));
    
  }
}
