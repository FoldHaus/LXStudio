public abstract class RadiaLumiaPattern extends LXModelPattern<Model> {
    public RadiaLumiaPattern(LX lx) {
        super(lx);
    }
    
    //NOTE(peter): umbrella position is in a range from (0, 1) inclusive
    public void setUmbrella(Bloom bloom, double position) {
        double ClampedPosition = clamp(position, 0, 1);
        final int positionSteps = RadiaNodeSpecialDatagram.MOTOR_DATA_MASK & (int) (bloom.umbrella.MaxPulses * ClampedPosition);
        this.colors[bloom.umbrella.position.index] = 0xff000000 | positionSteps;
    }
    
    //NOTE(peter): pin spot brightness is in a range from (0, 255) inclusive
    public void setPinSpot (Bloom bloom, int brightness) {
        println(brightness);
        this.colors[bloom.spike.pinSpot.index] = LXColor.rgba(brightness, brightness, brightness, brightness);
    }
}

// Static
@LXCategory("Texture")
public class Static extends RadiaLumiaPattern 
{
    public final CompoundParameter brightness = 
        new CompoundParameter ("Brightness", .1, 0,1)
        .setDescription("Set global brightness");
    
    public final CompoundParameter numPoints =  
        new CompoundParameter ("Points", 1, 0, 1000)
        .setDescription("Set number of sparkle points");
    
    public final DiscreteParameter maxDistance = 
        new DiscreteParameter ("Width", 1, 0, 100)
        .setDescription("Set distance of exapansion");
    
    public Static(LX lx) 
    {
        super(lx);
        addParameter(this.brightness); 
        addParameter(this.numPoints);
        addParameter(this.maxDistance);
        
    }
    
    public void run(double deltaMs) 
    {
        int curMaxValue = maxDistance.getValuei();
        double curBrightness = brightness.getValue();
        
        
        for (Bloom b : model.blooms) 
        { //loops through all blooms
            
            for (int p = 0; p < numPoints.getValue(); p++) 
            {
                
                int rI = (int)random((float)b.points.length);  
                
                int min = rI-curMaxValue; 
                if (min < 0) 
                {
                    min = 0; 
                }
                
                int max = rI+curMaxValue;
                if (max >= b.points.length) 
                {
                    max =  b.points.length-1;
                }
                
                for (int i=min; i<max; i++)
                {
                    double distance; 
                    distance = abs(i-rI)/(float)curMaxValue;
                    colors[b.points[i].index] = LXColor.hsb(0,0,(int)(curBrightness*255*distance));     
                }
            }
        }
    }
}


public class BlossomOscillation extends RadiaLumiaPattern {
    
    // half the distance away from the current position that is considered 'on'
    public final CompoundParameter fillRadius =
        new CompoundParameter("rad", .05, 0, .5)
        .setDescription("How wide the area turned on is.");
    
    // value determines the center of the area that is "on"
    public final SinLFO oscillator =
        new SinLFO(0, 1, 7000);
    
    public BlossomOscillation(LX lx) {
        super(lx);
        addParameter(this.fillRadius);
        startModulator(this.oscillator);
    }
    
    public void run(double deltaMs) {
        // The base values for the center, and width of the "on" area
        float center = (float) this.oscillator.getValue();
        float fillRadius = (float) this.fillRadius.getValue();
        
        // Converting base values into bounds
        float minOn = center - fillRadius;
        float maxOn = center + fillRadius;
        
        // The spike represents the area from [.5, 1] so we translate the min/max values into this space and clip them
        // to the bounds of the spike region. For example, if minOn = .2 and maxOn = .6, then spikeMinOn = 0 and spikeMaxOn = .2
        float spikeMinOn = constrain((minOn - .5) * 2, 0, 1);
        float spikeMaxOn = constrain((maxOn - .5) * 2, 0, 1);
        
        // Same as the spike, except that the spokes represent the region [0, .5]
        float spokesMinOn = constrain((minOn * 2), 0, 1);
        float spokesMaxOn = constrain((maxOn * 2), 0, 1);
        
        for (Bloom bloom : model.blooms) {
            
            // This was just so we could give each blossom a different color. Actually doesn't look great as is. This could be done elsewhere
            float hue = 360 * ((float) (bloom.id + 1) / (float) (model.blooms.size()));
            
            // Set the spike pixels which should be "on"
            for (LXPoint spikePoint : bloom.spike.points) {
                // the pixels distance from the blossom center
                float dst = new LXVector(spikePoint.x, spikePoint.y, spikePoint.z).dist(bloom.center);
                // the percentage of the total distance this pixel is
                float pctDst = (dst/bloom.maxSpikeDistance);
                
                float onMask = 0;
                // if the pctDst is between the spike normalized bounds, turn the pixel on
                if (pctDst > spikeMinOn && pctDst < spikeMaxOn) {
                    onMask = 100;
                }
                
                // set the color
                colors[spikePoint.index] = LXColor.hsb(hue, 100, onMask);
            }
            
            // This operates exactly the same as the spike, except that we invert pctDst so that the light flows up the spokes, towards the center, 
            // then up the spike, smoothly.
            for (LXPoint spokePoint : bloom.spokePoints) {
                float dst = new LXVector(spokePoint.x, spokePoint.y, spokePoint.z).dist(bloom.center);
                float pctDst = 1 - dst/bloom.maxSpikeDistance;
                float onMask = 0;
                if (pctDst > spokesMinOn && pctDst < spokesMaxOn) {
                    onMask = 100;
                }
                
                colors[spokePoint.index] = LXColor.hsb(hue, 100, onMask);
            }
        }
    }
}

public class PatternStarlight extends RadiaLumiaPattern {
  public String getAuthor() {
    return "Mark C. Slee";
  }
  
  final static int MAX_STARS = 100;
  final static int BLOOMS_PER_STAR = 3;
  
  final LXUtils.LookupTable flicker = new LXUtils.LookupTable(360, new LXUtils.LookupTable.Function() {
    public float compute(int i, int tableSize) {
      return .5 - .5 * cos(i * TWO_PI / tableSize);
    }
  });
  
  public final CompoundParameter speed =
    new CompoundParameter("Speed", 3000, 9000, 300)
    .setDescription("Speed of the twinkling");
    
  public final CompoundParameter variance =
    new CompoundParameter("Variance", .5, 0, .9)
    .setDescription("Variance of the twinkling");    
  
  public final CompoundParameter numStars = (CompoundParameter)
    new CompoundParameter("Num", 75, 50, MAX_STARS)
    .setExponent(2)
    .setDescription("Number of stars");
  
  private final Star[] stars = new Star[MAX_STARS];
    
  private final ArrayList<Bloom> shuffledBlooms;
    
  public PatternStarlight(LX lx) {
    super(lx);
    addParameter("speed", this.speed);
    addParameter("numStars", this.numStars);
    addParameter("variance", this.variance);
    // Trip - Wish there was a single data structure to access spokes...
    this.shuffledBlooms = new ArrayList<Bloom>(model.blooms); 
    Collections.shuffle(this.shuffledBlooms);
    for (int i = 0; i < MAX_STARS; ++i) {
      this.stars[i] = new Star(i);
    }
  }
  
  public void run(double deltaMs) {
    setColors(#000000);
    float numStars = this.numStars.getValuef();
    float speed = this.speed.getValuef();
    float variance = this.variance.getValuef();
    for (Star star : this.stars) {
      if (star.active) {
        star.run(deltaMs);
      } else if (star.num < numStars) {
        star.activate(speed, variance);
      }
    }
  }
  
  class Star {
    
    final int num;
    
    double period;
    float amplitude = 50;
    double accum = 0;
    boolean active = false;
    
    Star(int num) {
      this.num = num;
    }
    
    void activate(float speed, float variance) {
      this.period = max(400, speed * (1 + random(-variance, variance)));
      this.accum = 0;
      this.amplitude = random(20, 100);
      this.active = true;
    }
    
    void run(double deltaMs) {
      int c = LXColor.gray(this.amplitude * flicker.get(this.accum / this.period));
      int maxBlooms = shuffledBlooms.size();
      for (int i = 0; i < BLOOMS_PER_STAR; ++i) {
        int bloomIndex = num * BLOOMS_PER_STAR + i;
        if (bloomIndex < maxBlooms) {
          for (LXPoint light : shuffledBlooms.get(bloomIndex).leds) {
            colors[light.index] = c;
          }
        }
      }

      // for (LXPoint light : model.leds) {
      //       colors[light.index] = LXColor.hsb(100,100,100);
      //   }

      this.accum += deltaMs;
      if (this.accum > this.period) {
        this.active = false;
      }
    }
  }

}


// public class PatternSwarm extends RadiaLumiaPattern {
//   public String getAuthor() {
//     return "Mark C. Slee";
//   }
  
//   private static final int NUM_GROUPS = 5;

//   public final CompoundParameter speed = (CompoundParameter)
//     new CompoundParameter("Speed", 2000, 10000, 500)
//     .setDescription("Speed of swarm motion")
//     .setExponent(.25);
    
//   public final CompoundParameter base =
//     new CompoundParameter("Base", 10, 60, 1)
//     .setDescription("Base size of swarm");
    
//   public final CompoundParameter floor =
//     new CompoundParameter("Floor", 20, 0, 100)
//     .setDescription("Base level of swarm brightness");

//   public final LXModulator pos = startModulator(new SawLFO(0, LeafAssemblage.NUM_LEAVES - start, new FunctionalParameter() {
//         public double getValue() {
//           return speed.getValue() + ii*500;
//         }
//       }).randomBasis());

//   public final LXModulator swarmX = startModulator(new SinLFO(
//     startModulator(new SinLFO(0, .2, startModulator(new SinLFO(3000, 9000, 17000).randomBasis()))), 
//     startModulator(new SinLFO(.8, 1, startModulator(new SinLFO(4000, 7000, 15000).randomBasis()))), 
//     startModulator(new SinLFO(9000, 17000, 33000).randomBasis())
//     ).randomBasis());

//   public final LXModulator swarmY = startModulator(new SinLFO(
//     startModulator(new SinLFO(0, .2, startModulator(new SinLFO(3000, 9000, 19000).randomBasis()))), 
//     startModulator(new SinLFO(.8, 1, startModulator(new SinLFO(4000, 7000, 13000).randomBasis()))), 
//     startModulator(new SinLFO(9000, 17000, 33000).randomBasis())
//     ).randomBasis());

//   public final LXModulator swarmZ = startModulator(new SinLFO(
//     startModulator(new SinLFO(0, .2, startModulator(new SinLFO(3000, 9000, 19000).randomBasis()))), 
//     startModulator(new SinLFO(.8, 1, startModulator(new SinLFO(4000, 7000, 13000).randomBasis()))), 
//     startModulator(new SinLFO(9000, 17000, 33000).randomBasis())
//     ).randomBasis());

//   public PatternSwarm(LX lx) {
//     super(lx);
//     addParameter("speed", this.speed);
//     addParameter("base", this.base);
//     addParameter("floor", this.floor);
//     for (int i = 0; i < pos.length; ++i) {
//       final int ii = i;
//       float start = (i % 2 == 0) ? 0 : LeafAssemblage.NUM_LEAVES;
//       pos[i] = new SawLFO(start, LeafAssemblage.NUM_LEAVES - start, new FunctionalParameter() {
//         public double getValue() {
//           return speed.getValue() + ii*500;
//         }
//       }).randomBasis();
//       startModulator(pos[i]);
//     }
//   }

//   public void run(double deltaMs) {
//     float base = this.base.getValuef();
//     float swarmX = this.swarmX.getValuef();
//     float swarmY = this.swarmY.getValuef();
//     float swarmZ = this.swarmZ.getValuef();
//     float floor = this.floor.getValuef();

//     int i = 0;
//     // for (LeafAssemblage assemblage : tree.assemblages) {
//     //   float pos = this.pos[i++ % NUM_GROUPS].getValuef();
//     //   for (Leaf leaf : assemblage.leaves) {
//     //     float falloff = min(100, base + 40 * dist(leaf.point.xn, leaf.point.yn, leaf.point.zn, swarmX, swarmY, swarmZ));
//     //     float b = max(floor, 100 - falloff * LXUtils.wrapdistf(leaf.orientation.index, pos, LeafAssemblage.LEAVES.length));
//     //     setColor(leaf, LXColor.gray(b));
//     //   }
//     // }
//     for ( LXPoint led : model.leds ) {

//     }
//     for (LeafAssemblage assemblage : tree.assemblages) {
//       float pos = this.pos[i++ % NUM_GROUPS].getValuef();
//       for (Leaf leaf : assemblage.leaves) {
//         float falloff = min(100, base + 40 * dist(leaf.point.xn, leaf.point.yn, leaf.point.zn, swarmX, swarmY, swarmZ));
//         float b = max(floor, 100 - falloff * LXUtils.wrapdistf(leaf.orientation.index, pos, LeafAssemblage.LEAVES.length));
//         setColor(leaf, LXColor.gray(b));
//       }
//     }
//   }
// }

public class PatternClouds extends RadiaLumiaPattern {
  public String getAuthor() {
    return "Mark C. Slee";
  }
  
  public final CompoundParameter thickness =
    new CompoundParameter("Thickness", 50, 100, 0)
    .setDescription("Thickness of the cloud formation");
  
  public final CompoundParameter xSpeed = (CompoundParameter)
    new CompoundParameter("XSpd", 0.2, -1, 1)
    .setPolarity(LXParameter.Polarity.BIPOLAR)
    .setDescription("Motion along the X axis");

  public final CompoundParameter ySpeed = (CompoundParameter)
    new CompoundParameter("YSpd", 0.2, -1, 1)
    .setPolarity(LXParameter.Polarity.BIPOLAR)
    .setDescription("Motion along the Y axis");
    
  public final CompoundParameter zSpeed = (CompoundParameter)
    new CompoundParameter("ZSpd", 0.2, -1, 1)
    .setPolarity(LXParameter.Polarity.BIPOLAR)
    .setDescription("Motion along the Z axis");
    
  public final CompoundParameter scale = (CompoundParameter)
    new CompoundParameter("Scale", 2.5, .25, 10)
    .setDescription("Scale of the clouds")
    .setExponent(2);

  public final CompoundParameter xScale =
    new CompoundParameter("XScale", 0, 0, 10)
    .setDescription("Scale along the X axis");

  public final CompoundParameter yScale =
    new CompoundParameter("YScale", 0, 0, 10)
    .setDescription("Scale along the Y axis");
    
  public final CompoundParameter zScale =
    new CompoundParameter("ZScale", 0, 0, 10)
    .setDescription("Scale along the Z axis");
    
  private float xBasis = 0, yBasis = 0, zBasis = 0;
    
  public PatternClouds(LX lx) {
    super(lx);
    addParameter("thickness", this.thickness);
    addParameter("xSpeed", this.xSpeed);
    addParameter("ySpeed", this.ySpeed);
    addParameter("zSpeed", this.zSpeed);
    addParameter("scale", this.scale);
    addParameter("xScale", this.xScale);
    addParameter("yScale", this.yScale);
    addParameter("zScale", this.zScale);
  }

  private static final double MOTION = .0005;

  public void run(double deltaMs) {
    this.xBasis -= deltaMs * MOTION * this.xSpeed.getValuef();
    this.yBasis -= deltaMs * MOTION * this.ySpeed.getValuef();
    this.zBasis -= deltaMs * MOTION * this.zSpeed.getValuef();
    float thickness = this.thickness.getValuef();
    float scale = this.scale.getValuef();
    float xScale = this.xScale.getValuef();
    float yScale = this.yScale.getValuef();
    float zScale = this.zScale.getValuef();
    for (LXPoint p : model.leds) {
      float nv = noise(
        (scale + p.xn * xScale) * p.xn + this.xBasis,
        (scale + p.yn * yScale) * p.yn + this.yBasis, 
        (scale + p.zn * zScale) * p.zn + this.zBasis
      );
      colors[p.index] = LXColor.gray(constrain(-thickness + (150 + thickness) * nv, 0, 100));
    }
  }  
}
