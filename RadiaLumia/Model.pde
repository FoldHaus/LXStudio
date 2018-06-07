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

public static class Model extends LXModel {
  
  public final List<Bloom> blooms;
  public final List<LXPoint> leds;
  
  public Model(Config config) {
    super(new Fixture(config));
    Fixture f = (Fixture) this.fixtures.get(0);
    this.blooms = Collections.unmodifiableList(f.blooms);
    
    List<LXPoint> leds = new ArrayList<LXPoint>();
    for (Bloom bloom : this.blooms) {
      for (LXPoint p : bloom.leds) {
        leds.add(p);
      }
    }
    this.leds = Collections.unmodifiableList(leds);
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
  
  public final List<LXPoint> leds;
  public final Spike spike;
  public final List<Spoke> spokes;
  public final List<LXPoint> spokePoints;
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
    
    
    Fixture f = (Fixture) this.fixtures.get(0);
    this.center = f.center;
    this.spike = f.spike;
    this.spokes = f.spokes;
    this.umbrella = f.umbrella;
    
    List<LXPoint> leds = new ArrayList<LXPoint>();
    for (LXPoint p : this.spike.points) {
      leds.add(p);
    }
    
    // Make unmodifiable list of all spoke points for easy access
    List<LXPoint> spokePoints = new ArrayList<LXPoint>();
    for (Spoke spoke : this.spokes) {
      for (LXPoint p : spoke.points) {
        spokePoints.add(p);
        leds.add(p);
      }
    }
    this.spokePoints = Collections.unmodifiableList(spokePoints);
    
    this.leds = Collections.unmodifiableList(leds);
        
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
    for (LXPoint p : spokePoints) {
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
    private final List<Spoke> spokes = new ArrayList<Spoke>();
    private final Umbrella umbrella;
    
    Fixture(Config config, int index) {
      this.center = config.getBloomCenter(index); 
            
      this.spike = new Spike(this.center);
      addPoints(this.spike);
      
      int numSpokes = config.getBloom(index).getJSONArray("neighbors").size(); 
      for (int i = 0; i < numSpokes; ++i) {
        Spoke spoke = new Spoke(config, index, i);
        this.spokes.add(spoke);
        addPoints(spoke);
      }
      
      this.umbrella = new Umbrella();
      addPoints(this.umbrella);
    }
  }

  public static class Spike extends LXModel {
    
    public final static float LENGTH = 2 * METER;
    public final static int NUM_LEDS = 150;
    public final static float LED_PITCH = METER / 60.;
    
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
  
  public static class Spoke extends LXModel {
    
    public final static float LED_PITCH = METER / 144.;
    public final static int NUM_LEDS = 60;
    
    public final int spokeIndex;
    
    public Spoke(Config config, int bloomIndex, int spokeIndex) {
      super(new Fixture(config, bloomIndex, spokeIndex));
      this.spokeIndex = spokeIndex;
    }
  
    private static class Fixture extends LXAbstractFixture {
      public Fixture(Config config, int bloomIndex, int spokeIndex) {
        JSONObject bloomConfig = config.getBloom(bloomIndex);
        
        // Get neighbor center
        int neighborIndex = bloomConfig.getJSONArray("neighbors").getInt(spokeIndex);
        final LXVector neighborCenter = config.getBloomCenter(neighborIndex);
        
        // This bloom center
        final LXVector bloomCenter = config.getBloomCenter(bloomIndex);
        final LXVector bloomCenterNeg = bloomCenter.copy().mult(-1.f); 
        
        // Get direction from hub to neighbor
        LXVector delta = neighborCenter.copy().add(bloomCenterNeg);
          
        // Convert direction to unit vector and compute pitch
        float pitchMagnitude = (delta.mag() / 2.f) / NUM_LEDS;
        LXVector pitch = delta.normalize().mult(pitchMagnitude);          
        LXVector led = bloomCenter.copy();
        
        // Iterate along the extrusion
        for (int pixel = 0; pixel < NUM_LEDS; pixel++) {
          addPoint(new LXPoint(led));
          led.add(pitch);
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
  public static class Umbrella extends LXAbstractFixture {
    
    // Dummy point that holds the requested position of the Umbrella in the last byte
    // so 0xff000000 is 0% closed and 0xff0000ff is 100% closed 
    public final LXPoint position;    
    
    // An updated once-per-frame simulation of where we believe the motor to be based
    // upon its speed limitations
    public double simulatedPosition = 0.;
      
    private static final double FULL_OPEN_TO_CLOSE_TIME = 4000; // 4 Seconds
    private static final double UMBRELLA_MAX_VELOCITY = 1.0 / FULL_OPEN_TO_CLOSE_TIME;
      
    public Umbrella() {
      addPoint(this.position = new LXPoint(0, 0, 0));      
    }
    
    public void update(double deltaMs, int[] colors) {
      // TODO: should we model the motor's acceleration or response?
      double requestedPosition = (0xff & colors[this.position.index]) / 255.;
      double dist = requestedPosition - this.simulatedPosition;
      double maxMovement = UMBRELLA_MAX_VELOCITY * deltaMs;
      if (Math.abs(dist) > maxMovement) {
        this.simulatedPosition += maxMovement * (dist > 0 ? 1 : -1);
      } else {
        this.simulatedPosition = requestedPosition;
      }
    }
  }
}
