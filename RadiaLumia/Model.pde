import java.util.Collections;
import java.util.List;

class Config {
  
  public final static float SCALE = 14 * FEET;
  
  private final JSONObject j; 
  
  Config() {
    this.j = loadJSONObject("data/radialumia.json");
  }
  
  JSONArray getBlooms() {
    return this.j.getJSONArray("blooms");
  }
  
  JSONObject getBloom(int index) {
    return getBlooms().getJSONObject(index);
  }
  
  LXVector getBloomCenter(int index) {
    JSONObject bloom = getBloom(index);
    return new LXVector(bloom.getFloat("x"), bloom.getFloat("y"), bloom.getFloat("z")).mult(SCALE);
  }
}
  

Model buildModel() {
	return new Model(new Config());
}

public static class Model extends LXModel {
  
  public final List<Bloom> blooms;
  
  public Model(Config config) {
    super(new Fixture(config));
    Fixture f = (Fixture) this.fixtures.get(0);
    this.blooms = Collections.unmodifiableList(f.blooms);
  }
  
  public static class Fixture extends LXAbstractFixture {
    
    private final List<Bloom> blooms = new ArrayList<Bloom>();
    
    Fixture(Config config) {
      JSONArray bloomsConfig = config.getBlooms();
      int numBlooms = bloomsConfig.size();
      
      for (int i = 0; i < numBlooms; i++) {
        Bloom bloom = new Bloom(config, i);
        addPoints(bloom);
        this.blooms.add(bloom);
      }
      // Set up neighbor pointers
      for (Bloom bloom : this.blooms) {
        JSONArray bloomNeighbors = config.getBloom(bloom.index).getJSONArray("neighbors");
        int numNeighbors = bloomNeighbors.size();
        for (int i = 0; i < numNeighbors; ++i) {
          bloom.registerNeighbor(this.blooms.get(bloomNeighbors.getInt(i)));
        }
      }
    }
  }
}
  
public static class Bloom extends LXModel {
  
  public final int index;
  
  public final Spike spike;
  public final Spokes spokes;
  public final Umbrella umbrella;
  
  private final List<Bloom> _neighbors = new ArrayList<Bloom>();
  public final List<Bloom> neighbors = Collections.unmodifiableList(this._neighbors);
  
  public final LXVector center;
  public final float maxSpikeDistance;
  public final float maxSpokesDistance;

  public Bloom(Config config, int index) {
    super(new Fixture(config, index));
    JSONObject bloomConfig = config.getBloom(index); 
    this.index = bloomConfig.getInt("id");
    this.umbrella = new Umbrella(Umbrella.UmbrellaControlMode.OPEN_CLOSED_SWITCH);
    
    Fixture f = (Fixture) this.fixtures.get(0);
    this.center = f.center;
    this.spike = f.spike;
    this.spokes = f.spokes;
        
    float tempMaxDist = 0f;
    // Determine farthest distance along spike
    for (LXPoint p : spike.getPoints()) {
      LXVector pV = new LXVector (p.x, p.y, p.z);
      float dist = pV.dist(this.center);
      if (tempMaxDist < dist){
        tempMaxDist = dist;
      }
    }
    this.maxSpikeDistance = tempMaxDist;
    
    tempMaxDist = 0f;
    // Determine farthest distance along spokes
    for (LXPoint p : spokes.getPoints()) {
      LXVector pV = new LXVector(p.x, p.y, p.z);
      float dist = pV.dist(center);
      if (tempMaxDist < dist){
        tempMaxDist = dist;
      }
    }
    this.maxSpokesDistance = tempMaxDist;
  }
  
  protected void registerNeighbor(Bloom bloom) {
    this._neighbors.add(bloom);
  }
  
	private static class Fixture extends LXAbstractFixture {
  
    private final LXVector center;
    private final Spike spike;
    private final Spokes spokes;
  
    Fixture(Config config, int index) {
      this.center = config.getBloomCenter(index); 
      
      this.spike = new Spike(this.center);
      this.spokes = new Spokes(config, index);
      addPoints(this.spike);
      addPoints(this.spokes);
    }
  }

  public static class Spike extends LXModel {
    
    public final static float LENGTH = 10 * FEET;
    public final static int NUM_LEDS = 30;
    public final static float LED_PITCH = 100. / NUM_LEDS;
    
    public Spike(LXVector center) {
      super(new Fixture(center));
    }
    
    private static class Fixture extends LXAbstractFixture {
      public Fixture(LXVector spikeCenter) {
        LXVector led = spikeCenter.copy();
        LXVector pitch = spikeCenter.copy().normalize().mult(LED_PITCH);
        for (int pixel = 0; pixel < NUM_LEDS; pixel++) {
          addPoint(new LXPoint(led));
          led.add(pitch);
        }
      }
    }
  }
  
  public static class Spokes extends LXModel {
    
    public final static int NUM_LEDS = 30;
    public final static float LED_PITCH = 100./ NUM_LEDS;
    
    public Spokes(Config config, int index) {
      super(new Fixture(config, index));
    }
  
    private static class Fixture extends LXAbstractFixture {
      public Fixture(Config config, int index) {
        JSONObject bloomConfig = config.getBloom(index);
        
        // Geodesic extrusion strips
        JSONArray neighbors = bloomConfig.getJSONArray("neighbors");
        int numNeighbors = neighbors.size();
        int[] neighborIds = new int[numNeighbors];
        for (int i = 0; i < numNeighbors; ++i) {
          neighborIds[i] = neighbors.getInt(i);
        }
        
        final LXVector center = config.getBloomCenter(index);
        final LXVector centerNeg = center.copy().mult(-1.f); 
        
        // Iterate through neighbors
        for (int neighborId : neighborIds) {
          // Get direction from hub to neighbor
          LXVector delta = config.getBloomCenter(neighborId);
          delta.add(centerNeg);
          
          // Convert direction to unit vector and compute pitch
          float pitchMagnitude = (delta.mag() / 2.f) / NUM_LEDS;
          LXVector pitch = delta.normalize().mult(pitchMagnitude);          
          LXVector led = center.copy();
          
          // Iterate along the extrusion
          for (int pixel = 0; pixel < NUM_LEDS; pixel++) {
            addPoint(new LXPoint(led));
            led.add(pitch);
          }
        }
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
      } else if (mode == UmbrellaControlMode.PERCENT_CLOSED) {
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
      } else {
        percentClosed += umbrellaMaxPercentChangedPerSecond * deltaMs;
      }
  
      percentClosed = LXUtils.constrain(percentClosed, 0.0, 1.0);
    }
  }
}
