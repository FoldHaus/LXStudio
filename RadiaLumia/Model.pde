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
  
  JSONObject getBloom(int id) {
    return getBlooms().getJSONObject(id);
  }
  
  LXVector getBloomCenter(int id) {
    JSONObject bloom = getBloom(id);
    return new LXVector(bloom.getFloat("x"), bloom.getFloat("y"), bloom.getFloat("z")).mult(SCALE);
  }
}

public static class Model extends LXModel {
  
  public final List<Bloom> blooms;
  public final List<LXPoint> leds;
  public final Heart heart;

  // This is just a list of all the points that should be displayed in the simulation
  // This is made up of:
  // - Spike Points
  // - Spoke Points
  // - Pinspots
  // - Heart points
  public final List<LXPoint> displayPoints;

  public Model(Config config) {
    super(new Fixture(config));
    
    List<LXPoint> displayPoints_ = new ArrayList<LXPoint>();
    
    Fixture f = (Fixture) this.fixtures.get(0);
    this.blooms = Collections.unmodifiableList(f.blooms);
    
    
    List<LXPoint> leds = new ArrayList<LXPoint>();
    for (Bloom bloom : this.blooms) {
      for (LXPoint p : bloom.leds) {
        leds.add(p);
        displayPoints_.add(p);
      }
      displayPoints_.add(bloom.spike.pinSpot);
    }

    this.heart = f.heart;
    for (LXPoint p : heart.points) {
      leds.add(p);
      displayPoints_.add(p);
    }
    
    this.leds = Collections.unmodifiableList(leds);
    this.displayPoints = Collections.unmodifiableList(displayPoints_);
    println("Leds: " + this.leds.size());
    println("Length of led strips: " + (leds.size() / 60));
      
  }
  
  public static class Fixture extends LXAbstractFixture {

    private final List<Bloom> blooms = new ArrayList<Bloom>();
    private final Heart heart;
    
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
        JSONArray bloomNeighbors = config.getBloom(bloom.id).getJSONArray("neighbors");
        int numNeighbors = bloomNeighbors.size();
        for (int i = 0; i < numNeighbors; ++i) {
          bloom.registerNeighbor(this.blooms.get(bloomNeighbors.getInt(i)));
        }
      }
      
      heart = new Heart(this.blooms);
      addPoints(heart);
    }
  }
}
  
public static class Bloom extends LXModel {
  
  public final int id;
  
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

  public Bloom(Config config, int id) {
    super(new Fixture(config, id));
    JSONObject bloomConfig = config.getBloom(id);
    this.id = bloomConfig.getInt("id");
    
    
    Fixture f = (Fixture) this.fixtures.get(0);
    this.center = f.center;
    this.spike = f.spike;
    this.spokes = f.spokes;
    this.umbrella = f.umbrella;
    
    List<LXPoint> leds = new ArrayList<LXPoint>();
    for (LXPoint p : this.spike.leds) {
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
            
      this.spike = new Spike(config, index, this.center);
      addPoints(this.spike);
      
      int numSpokes = config.getBloom(index).getJSONArray("neighbors").size(); 
      
      if (numSpokes == 6) {
        SetHexaSpokes(config, index);
      }else{
        SetPentaSpokes(config, index);
      }
      
      this.umbrella = new Umbrella();
      addPoints(this.umbrella);
    }

    // SetPentaSpokes
    // All 5-strut hubs have 5 short struts, so no logic is needed to determine strut length
    public void SetPentaSpokes (Config config, int index) {
      
      boolean spokeIsShort = true;

      for (int i = 0; i < 5; i++) {
        //TODO(peter): set all penta spokes to be short
        Spoke spoke = new Spoke(config, index, i, spokeIsShort);
        this.spokes.add(spoke);
        addPoints(spoke);
      }
    }

    // SetHexaSpokes
    // Sets up spokes for 6-strut hubs. These hubs have 4 long and 2 short struts.
    // The two short struts always go from a 6-hub to a 5-hub, so we determine which are short
    // by looking at the # of neighbors associated with the hub each strut is going towards.
    public void SetHexaSpokes (Config config, int index) {
      for (int i = 0; i < 6; i++) {
        int neighborIndex = config.getBloom(index).getJSONArray("neighbors").getInt(i);
        int neighborNumSpokes = config.getBloom(neighborIndex).getJSONArray("neighbors").size();
        boolean spokeIsShort = neighborNumSpokes == 5;

        Spoke spoke = new Spoke(config, index, i, spokeIsShort);
        this.spokes.add(spoke);
        addPoints(spoke);
      }
    }
  }

  public static class Spike extends LXModel {
    
    public final static float LENGTH = 2 * METER;
    public final static int NUM_LEDS = 346;
    public final static float LED_PITCH = METER / 60.;
    
    // See Fixture.stripA and Fixture.stripB for documentation
    public final List<LXPoint> stripA;
    public final List<LXPoint> stripB;
    public final LXPoint pinSpot;

    public final List<LXPoint> leds;
    
    public Spike(Config config, int bloomIndex, LXVector center) {
      super(new Fixture(config, bloomIndex, center));

      Fixture f = (Fixture)this.fixtures.get(0);
      stripA = f.stripA;
      stripB = f.stripB;
      pinSpot = f.pinSpot;
      
      List<LXPoint> leds = new ArrayList<LXPoint>();
      for (LXPoint p : stripA) {
        leds.add(p);
      }
      for (LXPoint p : stripB) {
        leds.add(p);
      }
      
      this.leds = Collections.unmodifiableList(leds);
    }
    
    private static class Fixture extends LXAbstractFixture {

      public final List<LXPoint> stripA;
      public final List<LXPoint> stripB;
      public final LXPoint pinSpot;
      
      public Fixture(Config config, int bloomIndex, LXVector spikeCenter) {
        // Calculate Vector perpendicular to spike
        int firstNeighborIndex = config.getBloom(bloomIndex).getJSONArray("neighbors").getInt(0);
        LXVector firstNeighborCenter = config.getBloomCenter(firstNeighborIndex);
        LXVector perpendicularToSpike_a = firstNeighborCenter.copy().cross(spikeCenter).normalize().mult(1 * INCHES);
        
        int secondNeighborIndex = config.getBloom(bloomIndex).getJSONArray("neighbors").getInt(1);
        LXVector secondNeighborCenter = config.getBloomCenter(secondNeighborIndex);
        LXVector perpendicularToSpike_b = secondNeighborCenter.copy().cross(spikeCenter).normalize().mult(1 * INCHES);

        LXVector led_a = spikeCenter.copy().add(perpendicularToSpike_a);
        LXVector led_b = spikeCenter.copy().add(perpendicularToSpike_b);
        
        LXVector pitch = spikeCenter.copy().normalize().mult(LED_PITCH);
        
        stripA = new ArrayList<LXPoint>();
        stripB = new ArrayList<LXPoint>();
        
        // LEDs going Out
        for (int pixel = 0; pixel < NUM_LEDS / 2; pixel++) {
          addPoint(new LXPoint(led_a));
          stripA.add(this.points.get(this.points.size() - 1));
          
          addPoint(new LXPoint(led_b));
          stripB.add(this.points.get(this.points.size() - 1));
                     
          led_a.add(pitch);
          led_b.add(pitch);
        }
        
        LXVector pinspotPos = led_a.copy().add(led_b).mult(.5);
        pinspotPos = pinspotPos.add(pitch.copy().mult(10));
        addPoint(new LXPoint(pinspotPos));
        this.pinSpot = this.points.get(this.points.size() - 1);
        
        pitch = pitch.mult(-1);
        perpendicularToSpike_a = perpendicularToSpike_a.mult(-2);
        perpendicularToSpike_b = perpendicularToSpike_b.mult(-2);
        
        led_a.add(perpendicularToSpike_a);
        led_b.add(perpendicularToSpike_b);
        
        // LEDs coming in
        for (int pixel = 0; pixel < NUM_LEDS / 2; pixel++) {
          addPoint(new LXPoint(led_a));
          stripA.add(this.points.get(this.points.size() - 1));
          
          addPoint(new LXPoint(led_b));
          stripB.add(this.points.get(this.points.size() - 1));
          
          led_a.add(pitch);
          led_b.add(pitch);
        }
      }
    }
  }
  
  public static class Spoke extends LXModel {
    
    public final static float LED_PITCH = METER / 60.;
    public final static int LONG_NUM_LEDS = 123;
    public final static int SHORT_NUM_LEDS = 102;
    
    public final int spokeIndex;
    public final boolean isShort;
    public final int pointsAtBloomIndex;

    // See Fixture.inPoints an Fixture.outPoints for documentation
    public final List<LXPoint> inPoints;
    public final List<LXPoint> outPoints;

    public final float maxLedDistance;

    public Spoke(Config _config, int _bloomIndex, int _spokeIndex, boolean _isShort) {
      super(new Fixture(_config, _bloomIndex, _spokeIndex, _isShort));
      this.spokeIndex = _spokeIndex;
      this.isShort = _isShort;
      
      Fixture f = (Fixture)this.fixtures.get(0);
      this.inPoints = f.inPoints;
      this.outPoints = f.outPoints;

      this.pointsAtBloomIndex = _config.getBloom(_bloomIndex).getJSONArray("neighbors").getInt(_spokeIndex);
      this.maxLedDistance = f.maxLedDistance;
      
    }
  
    private static class Fixture extends LXAbstractFixture {

      // Logic behind lists of points:
      // Physically, each spoke has one line of leds which goes all the way to its neighbor, and another line
      // which comes all the way from that same neighbor. Visually, the half of both strips closest to each hub
      // should be associated with that hub. Arranging the data so it matches the physical setup should be done 
      // late so that patterns can be written with the visual logic taking presedence.
      
      // inPoints: The lights which, physically, receive data from the neighbor hub
      final List<LXPoint> inPoints = new ArrayList<LXPoint>();
      // outPoints: the lights which, physically, receive data from this hub
      final List<LXPoint> outPoints = new ArrayList<LXPoint>();

      final float maxLedDistance;
      
      public Fixture(Config config, int bloomIndex, int spokeIndex, boolean _isShort) {
        JSONObject bloomConfig = config.getBloom(bloomIndex);
        
        int numLeds = LONG_NUM_LEDS / 2;
        if (_isShort)
          numLeds = SHORT_NUM_LEDS / 2;
        
        // Get neighbor center
        int neighborIndex = bloomConfig.getJSONArray("neighbors").getInt(spokeIndex);
        final LXVector neighborCenter = config.getBloomCenter(neighborIndex);
        
        // This bloom center
        final LXVector bloomCenter = config.getBloomCenter(bloomIndex);
        final LXVector bloomCenterNeg = bloomCenter.copy().mult(-1.f); 
        
        // Get direction from hub to neighbor
        LXVector delta = neighborCenter.copy().add(bloomCenterNeg);
        
        // Vector perpendicular to the strut. Used to offset the in and out points
        LXVector perpendicularOffset = delta.copy().cross(bloomCenter).normalize().mult(1 * INCHES);
        LXVector negPerpendicularOffset = perpendicularOffset.copy().mult(-1);

        // Convert direction to unit vector and compute pitch
        float pitchMagnitude = (delta.mag() / 2.f) / numLeds;
        
        LXVector pitch = delta.normalize().mult(pitchMagnitude);          
        
        LXVector led_in = bloomCenter.copy().add(negPerpendicularOffset);
        LXVector led_out = bloomCenter.copy().add(perpendicularOffset);
        
        // Iterate along the extrusion
        for (int pixel = 0; pixel < numLeds; pixel++) {
          addPoint(new LXPoint(led_in));
          inPoints.add(this.points.get(this.points.size() - 1));
          
          addPoint(new LXPoint(led_out));
          outPoints.add(this.points.get(this.points.size() - 1));
          
          led_out.add(pitch);
          led_in.add(pitch);
        }

        maxLedDistance = (float)led_out.dist(bloomCenter);
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
    The motor has a defined max:
    - number of steps
    - velocity in steps/s
    - acceleration in steps/s/s
    These values can be extracted from the [NodeBox Firmware](https://github.com/FoldHaus/RadiaLumia-NodeBox-Firmware/blob/master/src/main.cpp)
    */
  public static class Umbrella extends LXAbstractFixture {
    
    // Dummy point that holds the requested position of the Umbrella in the last byte
    // so 0xff000000 is 0% expanded and 0xffxxxxxx is 100% closed
    public final LXPoint position;    
    
    // An updated once-per-frame simulation of where we believe the motor to be based
    // upon its speed limitations
    public double simulatedPosition = 0.;

    public static final int MaxSteps = 1234; // TODO: real number
    public static final int MaxStepsVel = 10000; // TODO: these match the code as it is, but that will change
    public static final int MaxStepsAcc = 50000; // TODO: these match the code as it is, but that will change

    private static final double FULL_OPEN_TO_CLOSE_TIME = 4000; // 4 Seconds
    private static final double UMBRELLA_MAX_VELOCITY = 1.0 / FULL_OPEN_TO_CLOSE_TIME;
      
    public Umbrella() {
      addPoint(this.position = new LXPoint(0, 0, 0));      
    }
    
    public void update(double deltaMs, int[] colors) {
      // TODO: should we model the motor's acceleration or response?
      double requestedPosition = (RadiaNodeSpecialDatagram.MOTOR_DATA_MASK & colors[this.position.index]);
      requestedPosition /= MaxSteps;
            
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

public static class Heart extends LXModel {
 
  
  public Heart (List<Bloom> _blooms) {
    super(new Fixture(_blooms));
  }
  
  public static class Fixture extends LXAbstractFixture {
    
    public List<Spine> spines = new ArrayList<Spine>();
    
    public Fixture(List<Bloom> _blooms) {
      for (Bloom bloom : _blooms) {
        if (bloom.neighbors.size() == 5) {
          spines.add(new Spine(bloom));
        }
      }
      
      for (Spine s : spines) {
        addPoints(s);
      }
    }
    
  }

  public static class Spine extends LXModel {
    
    public final static int LEDS_PER_SPINE = 123;
    public final static float LED_PITCH = METER / 120;
    
    public Spine(Bloom bloom) {
      super(new Fixture(bloom));
      
    }
    
    public static class Fixture extends LXAbstractFixture {
      
      public Fixture(Bloom bloom) {
        LXVector ledPos = new LXVector(0, 0, 0);
        LXVector pitch = bloom.center.copy().normalize().mult(LED_PITCH);
        
        for (int i = 0; i < LEDS_PER_SPINE; i++) {
          addPoint(new LXPoint(ledPos));
          ledPos.add(pitch);
        }
      }
    }
  }
}
