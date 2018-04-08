import java.util.Collections;
import java.util.List;

public final static float SPIKE_LENGTH = 10 * FEET;

public final static float LED_PER_SPOKE = 30.0;
public final static float LED_PER_SPIKE = 30.0;

public final static float LED_SPOKE_PITCH = 100./LED_PER_SPOKE;
public final static float LED_SPIKE_PITCH = 100./LED_PER_SPIKE;

GeodesicModel3D buildModel() {
	// A three-dimensional grid model
	// return new GridModel3D();
	return new GeodesicModel3D();
}

public static class GeodesicModel3D extends LXModel {
  
  public final static float SCALE = 14 * FEET;
  public final static float STRIP_LENGTH = 1.0;
  
  public final RadiaLumia radiaLumia;

  public final static LXVector hubs[] = {
    new LXVector(0.0000000, 0.5257311, 0.8506508),
    new LXVector(0.0000000, -0.5257311, 0.8506508),
    new LXVector(0.0000000, -0.5257311, -0.8506508),
    new LXVector(0.0000000, 0.5257311, -0.8506508),
    new LXVector(0.8506508, 0.0000000, 0.5257311),
    new LXVector(-0.8506508, 0.0000000, 0.5257311),
    new LXVector(-0.8506508, 0.0000000, -0.5257311),
    new LXVector(0.8506508, 0.0000000, -0.5257311),
    new LXVector(0.5257311, 0.8506508, 0.0000000),
    new LXVector(-0.5257311, 0.8506508, 0.0000000),
    new LXVector(-0.5257311, -0.8506508, 0.0000000),
    new LXVector(0.5257311, -0.8506508, 0.0000000),
    new LXVector(0.0000000, 0.0000000, 1.0000000),
    new LXVector(0.5000000, 0.3090170, 0.8090170),
    new LXVector(-0.5000000, 0.3090170, 0.8090170),
    new LXVector(0.3090170, 0.8090170, 0.5000000),
    new LXVector(-0.3090170, 0.8090170, 0.5000000),
    new LXVector(0.5000000, -0.3090170, 0.8090170),
    new LXVector(-0.5000000, -0.3090170, 0.8090170),
    new LXVector(-0.3090170, -0.8090170, 0.5000000),
    new LXVector(0.3090170, -0.8090170, 0.5000000),
    new LXVector(0.0000000, 0.0000000, -1.0000000),
    new LXVector(-0.5000000, -0.3090170, -0.8090170),
    new LXVector(0.5000000, -0.3090170, -0.8090170),
    new LXVector(-0.3090170, -0.8090170, -0.5000000),
    new LXVector(0.3090170, -0.8090170, -0.5000000),
    new LXVector(-0.5000000, 0.3090170, -0.8090170),
    new LXVector(0.5000000, 0.3090170, -0.8090170),
    new LXVector(0.3090170, 0.8090170, -0.5000000),
    new LXVector(-0.3090170, 0.8090170, -0.5000000),
    new LXVector(1.0000000, 0.0000000, 0.0000000),
    new LXVector(0.8090170, 0.5000000, 0.3090170),
    new LXVector(0.8090170, -0.5000000, 0.3090170),
    new LXVector(-1.0000000, 0.0000000, 0.0000000),
    new LXVector(-0.8090170, 0.5000000, 0.3090170),
    new LXVector(-0.8090170, -0.5000000, 0.3090170),
    new LXVector(-0.8090170, 0.5000000, -0.3090170),
    new LXVector(-0.8090170, -0.5000000, -0.3090170),
    new LXVector(0.8090170, 0.5000000, -0.3090170),
    new LXVector(0.8090170, -0.5000000, -0.3090170),
    new LXVector(0.0000000, 1.0000000, 0.0000000),
    new LXVector(0.0000000, -1.0000000, 0.000000)
  };


  public final static int[][] hub_graph = {
    {16,13,14,15,12},
    {20,18,17,19,12},
    {24,23,22,25,21},
    {28,26,27,29,21},
    {31,32,13,30,17},
    {14,35,34,18,33},
    {36,37,26,33,22},
    {30,27,39,38,23},
    {38,15,28,31,40},
    {36,40,34,29,16},
    {35,41,37,19,24},
    {32,25,20,39,41},
    {0,17,14,13,18,1},
    {17,15,4,0,31,12},
    {18,16,12,34,0,5},
    {8,13,40,31,16,0},
    {15,34,40,14,9,0},
    {4,20,13,32,12,1},
    {12,35,14,19,5,1},
    {41,18,20,35,1,10},
    {17,11,1,32,19,41},
    {3,22,27,26,23,2},
    {6,24,26,37,21,2},
    {21,39,27,25,7,2},
    {25,37,41,22,10,2},
    {11,23,41,39,24,2},
    {3,36,21,29,22,6},
    {38,3,7,28,23,21},
    {29,38,40,27,8,3},
    {9,26,40,36,28,3},
    {7,32,38,39,31,4},
    {30,15,38,13,8,4},
    {11,17,39,20,30,4},
    {5,37,34,35,36,6},
    {16,5,9,14,36,33},
    {5,19,33,18,37,10},
    {33,29,34,26,9,6},
    {10,22,35,24,33,6},
    {8,27,31,28,30,7},
    {30,25,32,23,11,7},
    {8,16,28,15,29,9},
    {11,24,20,25,19,10}
  };

  public GeodesicModel3D() {
    // for (int i = 0; i < hubs.length; i++) {
    //   super(new Fixture());
    // }
    //super(new Fixture());
    super(new RadiaLumia());
    
    radiaLumia = (RadiaLumia) this.fixtures.get(0);
  }
  
  public static class RadiaLumia extends LXAbstractFixture {
    
    public final Bloom[] blooms;
    
    RadiaLumia () {
      
      blooms = new Bloom[GeodesicModel3D.hubs.length];
      
      for (int i = 0; i < GeodesicModel3D.hubs.length; i++) {
        blooms[i] = new GeodesicModel3D.Bloom (i);
        addPoints (blooms[i]);
      } 
    }
  }
  
  public static class Bloom extends LXAbstractFixture {
    
	  public final int index;

    public final Spike spike;
    public final Spokes spokes;
    public final Umbrella umbrella;
    
    public final LXVector bloomCenter;
    public final float maxSpikeDistance;
    public final float maxSpokesDistance;
    
    Bloom (int bloomIndex) {
		index = bloomIndex;

      bloomCenter = hubs[bloomIndex].copy().mult(SCALE);
      
      spike = new Spike (bloomCenter);
      spokes = new Spokes(bloomIndex, bloomCenter);
      umbrella = new Umbrella(GeodesicModel3D.Umbrella.UmbrellaControlMode.OPEN_CLOSED_SWITCH);
      
      addPoints (spike);
      addPoints (spokes);
      
      float tempMaxDist = 0f;
      // Determine farthest distance along spike
      for (LXPoint p : spike.getPoints()) {
        LXVector pV = new LXVector (p.x, p.y, p.z);
        float dist = pV.dist(bloomCenter);
        if (tempMaxDist < dist){
          tempMaxDist = dist;
        }
      }
      maxSpikeDistance = tempMaxDist;
      
      tempMaxDist = 0f;
      // Determine farthest distance along spokes
      for (LXPoint p : spokes.getPoints()) {
        LXVector pV = new LXVector (p.x, p.y, p.z);
        float dist = pV.dist(bloomCenter);
        if (tempMaxDist < dist){
          tempMaxDist = dist;
        }
      }
      maxSpokesDistance = tempMaxDist;
    }
  }

  public static class Spokes extends LXAbstractFixture {
    Spokes(int hubIndex, LXVector hubCenter) {
      // Geodesic extrusion strips
        int[] neighborIds = hub_graph[hubIndex];
        
        // Iterate through neighbors
        for (int j = 0; j < neighborIds.length; j++) {

          // Get direction rom hub to neighbor
          LXVector n = hubs[neighborIds[j]].copy().mult(SCALE);
          n.add(hubCenter.copy().mult(-1.0));
          
          float led_pitch = (n.mag() / 2.f) / LED_PER_SPOKE;
          
          // Convert direction to unit vector
          n.normalize();
          
          
          // Iterate along the extrusion
          for (int pixel = 0; pixel < LED_PER_SPOKE; pixel++) {
            // Vector to store LED coordinates
            LXVector led = new LXVector(0,0,0);
            // Translate to hub
            led.add(hubCenter);
            // Translate along extrusion normal
            led.add(n.copy().mult(float(pixel)*led_pitch));
            addPoint(new LXPoint(
              led.x,
              led.y,
              led.z
            ));
          }
        }
    }
  }
  
  public static class Spike extends LXAbstractFixture {
    Spike (LXVector spikeCenter) {
        // Spike strips
        for (int pixel = 0; pixel < LED_PER_SPIKE; pixel++) {
          // Vector to store LED coordinates
          LXVector led = new LXVector(0,0,0);
          
          // Translate to hub
          led.add(spikeCenter);
          
          // Normal vector
          LXVector n = spikeCenter.copy().normalize();
          float spike_led_pitch = SPIKE_LENGTH / LED_PER_SPIKE;

          // Translate along normal
          led.add(n.mult(float(pixel)*LED_SPIKE_PITCH));
          addPoint(new LXPoint(
            led.x,
            led.y,
            led.z
          ));
        }
    }
  }
  
  /*
    Umbrella Class
    This class stores a model of the assumed current state of a physical umbrella on the structure

    It handles requests for the umbrella to reach states which are expressed in terms of percent closed
    For Example:
    - 1.0 = 100% Closed (looks like) <
    - 0.0 = 0% Closed  (looks like) (
    
    It also handles the modeling the behaviour of the motors, so that the visualization, and any requests,
    can be evaluated accurately and safely.

    Modeling the Motors
    Assumptions:
    - There are things we don't know about how the motors will behave. So we should let effects assume the best, and handle those assumptions in the model
    - The motor will have a defined speed
    - The motor may have a defined easing function
    - 
   */
  public static class Umbrella {
    
    private enum UmbrellaControlMode {
      PERCENT_CLOSED,
      OPEN_CLOSED_SWITCH,
    };

    private class WeightedPercentClosedRequest {
      public double value;
      public double weight;
      
      public WeightedPercentClosedRequest(double v, double w) {
        this.value = v;
        this.weight = w;
      }
    }

    public UmbrellaControlMode mode;
    
    //TODO(peter): separate state from constants
    private double umbrellaFullOpenToClosedTime = 4000; // 4 Seconds
    private double umbrellaMaxPercentChangedPerSecond = 1.0 / umbrellaFullOpenToClosedTime;

    private double mostRecent_TargetPercentClosedRequest;
    private double lastFrame_TargetPercentClosedRequest;

    private double percentClosed;
    private double timeMovingInThisDirection;
    
    private List<WeightedPercentClosedRequest> percentageRequests;

    public Umbrella (UmbrellaControlMode mode){
      this.mode = mode;

      percentClosed = 1;
      percentageRequests = new ArrayList<WeightedPercentClosedRequest>();
    }
    
    public void RequestPercentClosed (double value, double weight) {
       percentageRequests.add(new WeightedPercentClosedRequest(value, Math.max(0, Math.min(weight, 1))));
    }
    
    public double GetPercentClosed () {
      return percentClosed;
    }
    
    public void UpdateUmbrella (double deltaMs) {
      ApplyPercentageRequests();

      if (mode == UmbrellaControlMode.OPEN_CLOSED_SWITCH) {
        OpenClosedUpdate(deltaMs);        
      }else if (mode == UmbrellaControlMode.PERCENT_CLOSED) {
        percentClosed = mostRecent_TargetPercentClosedRequest;
      }
    }
    
    public void ApplyPercentageRequests () {
      if (percentageRequests.size() == 0)
        return;
        
      lastFrame_TargetPercentClosedRequest = mostRecent_TargetPercentClosedRequest;

      double newValue = 0;
      double totalWeight = 0;
      
      for (WeightedPercentClosedRequest r : percentageRequests) {
        if (r == null)
          continue; // TODO(peter): why would this ever happen???
          
        newValue += r.value * r.weight;
        totalWeight += r.weight;
      }
      
      if (totalWeight > 0) {
        newValue = newValue / totalWeight;
        mostRecent_TargetPercentClosedRequest = newValue;        
      }
      
      percentageRequests.clear();
    }

    public void OpenClosedUpdate (double deltaMs) {

      if (mostRecent_TargetPercentClosedRequest > .5) {
        percentClosed -= umbrellaMaxPercentChangedPerSecond * deltaMs;
      }else{
        percentClosed += umbrellaMaxPercentChangedPerSecond * deltaMs;
      }

      // Because processing doesn't have 'constrain' for doubles. Grrr
      if (percentClosed > 1.0) percentClosed = 1.0;
      if (percentClosed < 0.0) percentClosed = 0.0;
    }
  }
}
