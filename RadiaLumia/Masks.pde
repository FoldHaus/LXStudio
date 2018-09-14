
@LXCategory("Masks")
public class BloomPulse extends RadiaLumiaPattern {
    
    public final CompoundParameter P_OscillatorPeriod =
        new CompoundParameter("Period", 0, 10000);
    
    public final CompoundParameter P_PulseSize =
        new CompoundParameter("Size", 0, 1);
    
    public final SawLFO P_Offset =
        new SawLFO(0, TWO_PI, P_OscillatorPeriod);
    
    public BloomPulse(LX lx)
    {
        super(lx);
        
        addParameter(P_OscillatorPeriod);
        addParameter(P_PulseSize);
        
        startModulator(P_Offset);
    }
    
    public void run(double deltaMs)
    {
        
        float OscillatorValue = (float) this.P_Offset.getValue();
        float PulseSize = (float) this.P_PulseSize.getValue();
        
        LXVector PointVector;
        float Percent;
        float Offset;
        float Brightness;
        
        for (Bloom bloom : model.blooms)
        {
            // Spike
            for (LXPoint spike : bloom.spike.leds) 
            {
                PointVector = LXPointToVector(spike);
                Percent = 1 - (PointVector.dist(bloom.center) / bloom.maxSpikeDistance);
                Offset = (Percent + OscillatorValue) % TWO_PI;
                
                Brightness = constrain(sin(Offset / PulseSize) * 100, 0, 100);
                
                colors[spike.index] = LXColor.hsb(360, 0, Brightness);
            }
            
            for (LXPoint spoke : bloom.spokePoints) 
            {
                PointVector = LXPointToVector(spoke);
                Percent = PointVector.dist(bloom.center) / bloom.maxSpokesDistance;
                Offset = ((Percent * .5) + OscillatorValue) % TWO_PI;
                
                Brightness = constrain((sin(Offset / PulseSize) * 100), 0, 100);
                
                colors[spoke.index] = LXColor.hsb(360, 0, Brightness);
            }
        }
    }
}

// Sparkle
@LXCategory("Masks")
public class Sparkle extends RadiaLumiaPattern {
    
    // Parameters
    
    public final DiscreteParameter numFeatures = 
        new DiscreteParameter("num", 1, 0, 250);
    
    public final CompoundParameter feature_lifetime =
        new CompoundParameter("life", 1, 0, 30000);
    
    public final CompoundParameter  feature_size=
        new CompoundParameter("size", 1, 0, 100);
    
    public final CompoundParameter feature_brightness =
        new CompoundParameter("bri", 1, 0, 1);
    
    public final BooleanParameter P_OnlySpikes =
        new BooleanParameter("Spikes", false);
        
    // Instance Variables
    
    class FeaturePoint {
        public double currLifetime;
        public double maxLifetime;
        public LXVector position;
        
        public FeaturePoint(
            double lifetime,
            LXVector position
            ){
            this.maxLifetime = lifetime;
            this.position = position;
        }
    }
    
    List<FeaturePoint> feature_points;
    
    public Sparkle (LX lx){
        super(lx);
        
        addParameter(numFeatures);
        addParameter(feature_lifetime);
        addParameter(feature_size);
        addParameter(feature_brightness);
        addParameter(P_OnlySpikes);
        
        feature_points = new ArrayList<FeaturePoint>();
    }
    
    public void run(double deltaMs){
        
        if (numFeatures.getValuei() > feature_points.size()) {
            CacheFeaturePoints();
        }
        
        UpdateFeaturePoints(deltaMs);
        if (P_OnlySpikes.getValueb())
        {
          UpdateSpikeLeds();
        }
        else
        {
          UpdateLeds();
        }
    }
    
    public void CacheFeaturePoints() {
        
        // Create the feature points
        // How many?
        // Lifetime, max size, max brightness
        
        LXVector randPoint;
        
        for (int i = 0; i < numFeatures.getValuei(); i++) {
            feature_points.add(CreateNewFeaturePoint());
        }
        
        println(feature_points.size());
    }
    
    public FeaturePoint CreateNewFeaturePoint(){
        LXVector randPoint = LXPointToVector(
            model.leds.get(
            (int)(random(1) * model.leds.size())));
        
        double lifetime = feature_lifetime.getValue();
        lifetime += random((float)feature_lifetime.getValue()) - (.5 * feature_lifetime.getValue());
        
        FeaturePoint fpoint = new FeaturePoint(
            lifetime,
            randPoint
            );
        
        return fpoint;
    }
    
    public void UpdateFeaturePoints(double deltaMs) {
        
        // Update all feature points
        // 1. Update lifetime
        // 2. Update size based on lifetime
        // 3. Update brightness based on lifetime
        
        for (int f = 0; f < numFeatures.getValuei(); f++) {
            feature_points.get(f).currLifetime += deltaMs;
            
            if (feature_points.get(f).currLifetime >= feature_points.get(f).maxLifetime) {
                feature_points.set(f, CreateNewFeaturePoint());
            }
        }
        
    }
    
    public void UpdateLeds() {
        
        // Update all leds
        // 1. Check distance to every feature point
        // 2. Update brightness based on closest feature point
        
        LXVector led_point;
        
        int closest_feature_index = -1;
        double closest_feature_distance = 10000;
        
        double maxDistance = feature_size.getValue();
        double maxBrightness = feature_brightness.getValue();
        
        for(LXPoint p : model.leds) {
            
            // Reset
            closest_feature_index = -1;
            closest_feature_distance = 10000;
            
            led_point = LXPointToVector(p);
            
            // Get closest feature point
            for (int f = 0; f < numFeatures.getValuei(); f++) {
                
                double distance = led_point.dist(feature_points.get(f).position);
                
                if (distance < closest_feature_distance) {
                    closest_feature_distance = distance;
                    closest_feature_index = f;
                }
            }
            
            double feature_decay = feature_points.get(closest_feature_index).currLifetime / feature_points.get(closest_feature_index).maxLifetime;
            feature_decay = 6.28  * (1.0 - feature_decay);
            feature_decay = .5 + (.5 * sin((float)feature_decay));
            
            double curr_distance = closest_feature_distance / maxDistance;
            curr_distance = clamp(curr_distance, 0, 1);
            curr_distance = 1 - curr_distance;
            
            double led_brightness = feature_decay * curr_distance;
            led_brightness *= maxBrightness;
            
            if (closest_feature_index == -1)
                led_brightness = 0;
            
            colors[p.index] = LXColor.hsb(0, 0, (int)(led_brightness * 100));
        }
    }
    
    public void UpdateSpikeLeds() {
        
        // Update all leds
        // 1. Check distance to every feature point
        // 2. Update brightness based on closest feature point
        
        LXVector led_point;
        
        int closest_feature_index = -1;
        double closest_feature_distance = 10000;
        
        double maxDistance = feature_size.getValue();
        double maxBrightness = feature_brightness.getValue();
        
        for(Bloom b : model.blooms)
        {
          for(LXPoint p : b.spike.leds) {
              
              // Reset
              closest_feature_index = -1;
              closest_feature_distance = 10000;
              
              led_point = LXPointToVector(p);
              
              // Get closest feature point
              for (int f = 0; f < numFeatures.getValuei(); f++) {
                  
                  double distance = led_point.dist(feature_points.get(f).position);
                  
                  if (distance < closest_feature_distance) {
                      closest_feature_distance = distance;
                      closest_feature_index = f;
                  }
              }
              
              double feature_decay = feature_points.get(closest_feature_index).currLifetime / feature_points.get(closest_feature_index).maxLifetime;
              feature_decay = 6.28  * (1.0 - feature_decay);
              feature_decay = .5 + (.5 * sin((float)feature_decay));
              
              double curr_distance = closest_feature_distance / maxDistance;
              curr_distance = clamp(curr_distance, 0, 1);
              curr_distance = 1 - curr_distance;
              
              double led_brightness = feature_decay * curr_distance;
              led_brightness *= maxBrightness;
              
              if (closest_feature_index == -1)
                  led_brightness = 0;
              
              colors[p.index] = LXColor.hsb(0, 0, (int)(led_brightness * 100));
          }
        }
    }
    
}

@LXCategory("Masks")
public class RadialSinWave extends RadiaLumiaPattern {
    
    public final CompoundParameter P_Period =
        new CompoundParameter("per", .05, 0, .5)
        .setDescription("The period of the sin wave");
    
    public final CompoundParameter P_Speed = 
        new CompoundParameter("off", 1, 5000, 1)
        .setDescription("Current offset of the sin wave");
    
    public final CompoundParameter P_Width = 
        new CompoundParameter("wid", .05, 0, 1)
        .setDescription("Width of the sin wave");
    
    public final CompoundParameter P_SampleSpacing = 
        new CompoundParameter("spc", .2, 0.0, 1.0)
        .setDescription("Spacing between samples of the sin wave, in percent of 2*PI");
    
    public final SawLFO P_Offset =
        new SawLFO(0, TWO_PI, P_Speed);
    
    public RadialSinWave(LX lx){
        super(lx);
        addParameter(P_Period);
        addParameter(P_Speed);
        addParameter(P_Width);
        addParameter(P_SampleSpacing);
        
        startModulator(P_Offset);
    }
    
    public void run(double deltaMs) {
        
        double bloomAcc = 0;
        double x = 0.0;
        double sinValue = 0.0;
        
        double per = P_Period.getValue();
        double off = P_Offset.getValue();
        double wid = P_Width.getValue();
        double spc = P_SampleSpacing.getValue();
        
        double light_percent = 0.0;
        double brightness_value = 0.0;
        
        for (Bloom bloom: model.blooms) 
        {
            bloomAcc += 1;
            x = 0.0;
            
            for (Bloom.Spoke spoke : bloom.spokes) 
            {
                x += bloomAcc + ((TWO_PI) * spc);
                sinValue = (double)(.5 + .5 * sin((float)(per + (off + x)) % TWO_PI));
                
                for (LXPoint light : spoke.points) 
                {
                    LXVector lightPos = new LXVector(light.x, light.y, light.z);
                    double dist_from_center = lightPos.dist(bloom.center);
                    double pct_along_spoke = dist_from_center / (2 * bloom.maxSpokesDistance);
                    
                    double dist_from_sin_val = pct_along_spoke - sinValue;
                    
                    
                    
                    light_percent = new LXVector(light.x, light.y, light.z).dist(bloom.center) / (2 * bloom.maxSpokesDistance);
                    brightness_value = abs((float)(light_percent - sinValue)) < (float)wid ? 100 : 0;
                    colors[light.index] = LXColor.hsb(360, 0, brightness_value);
                }
            }
        }
    }
}

@LXCategory("Masks")
public class DotMask extends RadiaLumiaPattern
{
    
    public final CompoundParameter P_Speed =
        new CompoundParameter("Speed", 1000, 60000, 1);
    
    public final CompoundParameter P_DotSize =
        new CompoundParameter("Size", .5, 0, 1);
    
    public final CompoundParameter P_AnimTime =
        new CompoundParameter("A Time", 1000, 10000, 1);
    
    public final CompoundParameter P_OffTime =
        new CompoundParameter("O Time", 5000, 30000, 1);
    
    public SawLFO Oscillator = 
        new SawLFO(-1, 3, P_Speed);
    
    public DotMask(LX lx)
    {
        super(lx);
        
        addParameter(P_Speed);
        addParameter(P_DotSize);
        addParameter(P_AnimTime);
        addParameter(P_OffTime);
        
        startModulator(Oscillator);
    }
    
    public void run (double deltaMs)
    {
        
        float RadiusPercent = P_DotSize.getValuef();
        float OscillatorValue = constrain(Oscillator.getValuef(), -1, 1);
        
        float AnimTime = P_AnimTime.getValuef();
        float OffTime = P_OffTime.getValuef();
        
        LXVector BloomCenter;
        float MaxDistance;
        float Radius;
        
        LXVector PointVector;
        float Distance;
        
        float AnimationPosition;
        
        int Accumulator = 0;
        
        for (Bloom b : model.blooms)
        {
            BloomCenter = b.center;
            MaxDistance = b.maxSpokesDistance;
            
            // TODO(peter): Make this offset somehow per bloom
            AnimationPosition = OscillatorValue + Accumulator++;
            
            // abs(((cos(PI + X * 4) * .5) + .5) * X * 1.2) ^ 4.2)
            //Radius = MaxDistance * RadiusPercent;
            Radius = abs(((cos(PI + AnimationPosition * 4) * .5) + .5) * AnimationPosition * 1.2); 
            
            Radius = pow(Radius, 4.2);
            
            println(OscillatorValue + " : " + Radius);
            
            Radius *= MaxDistance * RadiusPercent;
            
            for (LXPoint p : b.leds)
            {
                PointVector = LXPointToVector(p);
                Distance = PointVector.dist(BloomCenter);
                
                if (Distance <= Radius)
                {
                    colors[p.index] = LXColor.WHITE;
                }else{
                    colors[p.index] = LXColor.BLACK;
                }
            }
        }
    }
}


@LXCategory("Masks")
public class Ripple extends RadiaLumiaPattern {
    
    public final CompoundParameter period =
        new CompoundParameter("per", 10, 0, 50)
        .setDescription("The period of the sin wave");
    
    // public final DiscreteParameter epicenter =
    //   new DiscreteParameter("epi", 13, 0, 41);
    
    public final CompoundParameter offset = 
        new CompoundParameter("off", 0, 0, 2 * 3.14)
        .setDescription("Current offset of the sin wave");
    
    public final CompoundParameter speed = 
        new CompoundParameter("spe", 500, 5000, 0)
        .setDescription("Current offset of the sin wave");
    
    public final SawLFO oscillator =
        new SawLFO(0, 2 * 3.14, speed);
    
    
    public Ripple(LX lx){
        super(lx);
        addParameter(this.period);
        // addParameter(this.epicenter);
        // addParameter(this.offset);
        addParameter(this.speed);
        startModulator(this.oscillator);
    }
    
    public void run(double deltaMs) {
        
        
        double per = this.period.getValue();
        // int epi = this.epicenter.getValuei();
        // double off = this.offset.getValue();
        
        double off = this.oscillator.getValue();
        
        double sinValue = 0.0;
        double dist_from_center_percent = 0.0;
        double brightness_value = 0.0;
        
        
        LXVector bloomCenter = model.blooms.get(5).center;
        
        for (Bloom bloom: model.blooms) {
            
            
            
            for (LXPoint led : bloom.spike.leds) {
                LXVector ledVector = LXPointToVector(led);
                
                dist_from_center_percent = ledVector.dist(bloomCenter) / (bloom.maxSpokesDistance);
                
                sinValue = (double)(sin(off + per * dist_from_center_percent));
                
                sinValue = 0.5 + 0.8 * sinValue;
                sinValue = (double) constrain((float)sinValue, 0.f , 1);
                
                brightness_value = 100 * sinValue;      
                
                colors[led.index] = LXColor.hsb(360, 0, brightness_value);
            }
            
            for (Bloom.Spoke spoke : bloom.spokes) {
                for (LXPoint light : spoke.points) {
                    
                    LXVector lightVector = LXPointToVector(light);
                    
                    
                    dist_from_center_percent = lightVector.dist(bloomCenter) / (bloom.maxSpokesDistance);
                    
                    sinValue = (double)(sin(off + per * dist_from_center_percent));
                    
                    sinValue = 0.5 + 0.5 * sinValue;
                    brightness_value = 100 * sinValue;          
                    colors[light.index] = LXColor.hsb(360, 0, brightness_value);
                }
            }
            
        }
    }
}

public class VerticalRangeMask extends RadiaLumiaPattern
{
   public final CompoundParameter P_RangeBottom =
     new CompoundParameter("Bottom", 0, -300, 300);
   
   public final CompoundParameter P_RangeTop =
     new CompoundParameter("Top", 0, -300, 300);
   
   public VerticalRangeMask (LX lx)
   {
       super(lx);
       addParameter(P_RangeBottom);
       addParameter(P_RangeTop);
   }
   
   public void run (double deltaMs)
   {
      float RangeBottom = min(P_RangeBottom.getValuef(), P_RangeTop.getValuef());
      float RangeTop = max(P_RangeBottom.getValuef(), P_RangeTop.getValuef());
      
      for (LXPoint p : model.leds)
      {
          if (p.y >= RangeBottom && p.y <= RangeTop)
          {
             colors[p.index] = LXColor.WHITE; 
          }
          else
          {
             colors[p.index] = LXColor.BLACK; 
          }
      }
   }
}

// Belongs in DiscPatterns
@LXCategory("Masks")
public class VelocityDisks extends RadiaLumiaPattern {
        
     public final CompoundParameter P_RotationVelY = 
        new CompoundParameter ("offY", 0, 5 * SECONDS, 30 * SECONDS); 
    
    public final CompoundParameter P_RotationVelZ =
        new CompoundParameter("VelZ", 5 * SECONDS, 0, 30 * SECONDS)
        .setDescription("The offset from the root for each successive disc");
    
    public final DiscreteParameter P_DiscCount = 
        new DiscreteParameter("num", 1, 1, 10)
        .setDescription("The number of discs.");  
    
    public final CompoundParameter P_DiscWidth = 
        new CompoundParameter("wid", .2, 0.0, 200.0);
    
    public final CompoundParameter P_InnerRadius = 
        new CompoundParameter("inRad", 0, 0, 320);
    
    public final CompoundParameter P_OuterRadius = 
        new CompoundParameter("outRad", 320, 0, 320);
    
    public final SawLFO P_RotationY = 
        new SawLFO(0, TWO_PI, P_RotationVelY);
    
    public final SawLFO P_RotationZ = 
        new SawLFO(0, TWO_PI, P_RotationVelZ);
   
    
    public VelocityDisks (LX lx) {
        super(lx);
        addParameter(P_RotationVelY);
        addParameter(P_RotationVelZ);
        addParameter(P_DiscCount);
        addParameter(P_DiscWidth);
        addParameter(P_InnerRadius);
        addParameter(P_OuterRadius);
        
        startModulator(P_RotationY);
        startModulator(P_RotationZ);
    }
    
    public void run (double deltaMs) {
        
        float theta_Z;
        float theta_Y;
        float width = P_DiscWidth.getValuef();
        
        LXVector center = new LXVector(0, 0, 0);
        LXVector c_normal;
        
        LXVector front_center;
        LXVector back_center;
        
        LXVector p_vec;
        LXVector front_to_p;
        LXVector back_to_p;
        float front_dot_n;
        float back_dot_n;
        
        double maxRadius = P_OuterRadius.getValue();
        double minRadius = P_InnerRadius.getValue();
        
        LXVector[] front_centers = new LXVector[P_DiscCount.getValuei()];
        LXVector[] back_centers = new LXVector[P_DiscCount.getValuei()];
        LXVector[] normals = new LXVector[P_DiscCount.getValuei()];
        
        for (int disc = 0; disc < P_DiscCount.getValuei(); disc++) {
            theta_Z = ((float)P_RotationZ.getValue() + (float)disc);
            theta_Y = (float)P_RotationY.getValue() + (float)disc;
            
            c_normal = new LXVector(cos(theta_Z), 0.0, sin(theta_Z)).normalize();
            LXVector l_right = c_normal.copy().cross(new LXVector(0, 1, 0));
            c_normal = c_normal.rotate(theta_Y, l_right.x, l_right.y, l_right.z);
            
            normals[disc] = c_normal;
            front_centers[disc] = center.copy().add(c_normal.copy().mult(-width));
            back_centers[disc] = center.copy().add(c_normal.copy().mult(width));
        }
        
        for (LXPoint p : model.leds) {
            p_vec = new LXVector(p.x, p.y, p.z);
            
            boolean inAPlane = false;
            
            for (int d = 0; d < P_DiscCount.getValuei(); d++) {
                LXVector to_front = p_vec.copy().add(front_centers[d]);
                LXVector to_back = p_vec.copy().add(back_centers[d]);  
                
                float p_dot_front = to_front.copy().normalize().dot(normals[d]);
                float p_dot_back = to_back.copy().normalize().dot(normals[d]);
                
                p_dot_front *= 1000;
                p_dot_front = 1 - constrain(p_dot_front, 0, 1);
                
                p_dot_back *= 1000;
                p_dot_back = constrain(p_dot_back, 0, 1);
                
                double distToCenter = p_vec.copy().mag();
                if (p_dot_front > 0 && p_dot_back > 0 && distToCenter < maxRadius && distToCenter > minRadius) {
                    inAPlane = true;
                    break;
                }
            }
            
            if (inAPlane) {
                colors[p.index] = LXColor.WHITE; 
            }else{
                colors[p.index] = LXColor.BLACK;
            }
        } 
    }
}

    
 public class HeartOn extends RadiaLumiaPattern
 {
     public HeartOn (LX lx)
     {
       super(lx);
     }
     
     public void run (double deltaMs)
     {
        for (LXPoint p : model.heart.points)
        {
           colors[p.index] = LXColor.WHITE; 
        }
     }
 }
