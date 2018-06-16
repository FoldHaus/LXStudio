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
public class RadiaEntranceEffect extends RadiaLumiaPattern {

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
    
    // TODO(peter): do this in an array
    double c12_radius = bloomOneState.getValue() * FEET;
    double c23_radius = bloomTwoState.getValue() * FEET;
    double c31_radius = bloomThreeState.getValue() * FEET;
    
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
    setUmbrella(bloomOne, bloomOne_InCircleMask);
    setUmbrella(bloomTwo, bloomTwo_InCircleMask);
    setUmbrella(bloomThree, bloomThree_InCircleMask);
  }
}
