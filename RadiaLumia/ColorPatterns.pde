@LXCategory("Color")
public class ColorSpheres extends RadiaLumiaPattern {
    
    public final CompoundParameter P_SphereBaseSize = 
        new CompoundParameter("size", 1, 0, 350);
    
    public final CompoundParameter P_DeltaMagnitude =
        new CompoundParameter("dmag", 0, 0, 300);
    
    public final CompoundParameter P_AngleOffset =
        new CompoundParameter("off", 0, 0, 300);
    
    public ColorSpheres (LX lx) {
        super(lx);
        addParameter(P_SphereBaseSize);
        addParameter(P_DeltaMagnitude);
        addParameter(P_AngleOffset);
    }
    
    public void run (double deltaMs) {
        
        double diameter = P_SphereBaseSize.getValue();
        float theta = (float)(P_AngleOffset.getValue());
        float delta_mag = (float)(P_DeltaMagnitude.getValue());
        
        LXVector sphereA_pos = new LXVector(sin(theta), sin(.835 * (theta + .3251)), cos(theta)).normalize().mult(delta_mag);
        LXVector sphereB_pos = new LXVector(sin(-theta + .3), cos(.831 * (theta + .3415) + .3), cos(-theta + .3)).normalize().mult(delta_mag);
        
        double a_distance = 0;
        double a_pct_diameter = 0;
        double b_distance = 0;
        double b_pct_diameter = 0;
        
        LXVector light_pos;
        
        float hueA = palette.getHuef();
        float hueB = (hueA + (sin(theta * .162 + .138) * 360)) % 360;
        float hueC = (hueA + (sin(theta - .183) * 360)) % 360;
        
        for (LXPoint light : model.leds) {
            light_pos = new LXVector(light.x, light.y, light.z);
            
            a_distance = light_pos.dist(sphereA_pos);
            a_pct_diameter = clamp((a_distance / diameter), 0, 1);
            
            b_distance = light_pos.dist(sphereB_pos);
            b_pct_diameter = clamp((b_distance / diameter), 0, 1);
            
            int colA = LXColor.lerp(LXColor.hsb(hueA, 100, 100), LXColor.BLACK, a_pct_diameter);
            int colB = LXColor.lerp(LXColor.hsb(hueB, 100, 100), LXColor.BLACK, b_pct_diameter);
            
            int colC = LXColor.hsb(hueC, 100, 25);
            
            int finalCol = LXColor.add(colA, LXColor.add(colB, colC));
            double brightnessPct = (double)(LXColor.b(finalCol)) / 100;
            finalCol = LXColor.lerp(colC, finalCol, brightnessPct);
            //LXColor.lerp(colA, colB, a_pct_diameter / (a_pct_diameter + b_pct_diameter));
            //finalCol = LXColor.lerp(colC, finalCol, c_pct_diameter / (a_pct_diameter + b_pct_diameter + c_pct_diameter));
            
            colors[light.index] = finalCol;
        }
    }
}

@LXCategory("Color")
public class RadialGradient extends RadiaLumiaPattern
{
    
    public final CompoundParameter P_MotionSpeed = 
        new CompoundParameter("mspd", 1, 0, 10000)
        .setDescription("Speed of the stripe movement");
    
    public final CompoundParameter P_ColorPeriod = 
        new CompoundParameter("cpd", 1, 0, 5)
        .setDescription("The period of color oscillation");
        
    public final BooleanParameter P_ColorTakeover =
        new BooleanParameter("Takeover", false);
        
    public final CompoundParameter P_TakeoverSpeed =
        new CompoundParameter("TSpd", 3000, 0, 60000);
    
    public final CompoundParameter P_TakeoverFrequency =
        new CompoundParameter("TFreq", 3000, 0, 60000);
    
    public final SawLFO Progress =
        new SawLFO(0, 360, P_MotionSpeed);
    
    public final SawLFO P_TakeoverProgress =
        new SawLFO(0, 1, P_TakeoverFrequency);
        
    int TakeoverCenter;
    
    public RadialGradient (LX lx)
    {
        super(lx);
        
        addParameter(P_MotionSpeed);
        addParameter(P_ColorPeriod);
        
        addParameter(P_ColorTakeover);
        addParameter(P_TakeoverSpeed);
        addParameter(P_TakeoverFrequency);
        
        startModulator(Progress);
        startModulator(P_TakeoverProgress);
    }
    
    public void run (double deltaMs)
    {
        double LedDistance;
        double LedPctDistance;
        
        double ColorPeriod = P_ColorPeriod.getValue();
        double ColorOffset = Progress.getValue();
        
        float BaseHue = palette.getHuef();
        
        for (Bloom bloom : model.blooms)
        {
            for (LXPoint spikePoint : bloom.spike.leds)
            {
                LedDistance = new LXVector(spikePoint.x, spikePoint.y, spikePoint.z).dist(bloom.center);
                // the percentage of the total distance this pixel is
                LedPctDistance = (LedDistance/bloom.maxSpikeDistance);
                
                float Hue = (BaseHue + (float)(360 * (LedPctDistance * ColorPeriod) + ColorOffset)) % 360;
                colors[spikePoint.index] = LXColor.hsb(Hue, 100, 100);
            }
            
            for (LXPoint spokePoint : bloom.spokePoints)
            {
                LedDistance = new LXVector(spokePoint.x, spokePoint.y, spokePoint.z).dist(bloom.center);
                LedPctDistance = (LedDistance/bloom.maxSpikeDistance);
                
                
                float Hue = (BaseHue + (float)(360 * (LedPctDistance * ColorPeriod) + ColorOffset)) % 360;
                colors[spokePoint.index] = LXColor.hsb(Hue, 100, 100);
            }
        }
        
        if (P_ColorTakeover.getValueb())
        {
          float TakeoverProgress = P_TakeoverProgress.getValuef();
          
          if (abs(TakeoverProgress - .001f) < .01)
          {
             TakeoverCenter = (int)random(0, 42);
          }
          
          float TakeoverRadius = TakeoverProgress * 300;
          LXVector CenterVector = model.blooms.get(TakeoverCenter).center;
          
          for (LXPoint p : model.leds)
          {
             LXVector pVector = LXPointToVector(p);
             if (pVector.dist(CenterVector) < TakeoverRadius)
             {
                colors[p.index] = LXColor.hsb(palette.getHuef(), 100, 100);
             }
          }
        }
    }
}


@LXCategory("Color")
public class RadialStripes extends RadiaLumiaPattern
{
    
    public final CompoundParameter P_MotionSpeed = 
        new CompoundParameter("mspd", 1, 5000, 0)
        .setDescription("Speed of the stripe movement");
    
    public final CompoundParameter P_ColorPeriod = 
        new CompoundParameter("cpd", 1, 0, 5)
        .setDescription("The period of color oscillation");
    
    public final CompoundParameter P_Warp =
        new CompoundParameter("wst", 0, 0, 1)
        .setDescription("The amount of warping to apply to the stripes");
    
    public final CompoundParameter P_WarpFrequency =
        new CompoundParameter("wfq", 0, 0, 5)
        .setDescription("The amount of warping to apply to the stripes");
    
    public final CompoundParameter P_ColorDelta = 
        new CompoundParameter("cdelta", PI, 0, TWO_PI);
    
    public final SawLFO Progress =
        new SawLFO(0, 6, P_MotionSpeed);
    
    public RadialStripes (LX lx)
    {
        super(lx);
        
        addParameter(P_MotionSpeed);
        addParameter(P_ColorPeriod);
        addParameter(P_Warp);
        addParameter(P_WarpFrequency);
        addParameter(P_ColorDelta);
        
        startModulator(Progress);
    }
    
    public void run (double deltaMs)
    {
        double LedDistance;
        double LedPctDistance;
        double ColorLerpValue;
        double WarpAmount;
        double ColorAmount;
        
        double Period = P_ColorPeriod.getValue();
        double Offset = Progress.getValue();
        double WarpStrength = P_Warp.getValue();
        double WarpFrequency = P_WarpFrequency.getValue();
        
        int ColorA = palette.getColor();
        int ColorB = LXColor.hsb(palette.getHuef() + P_ColorDelta.getValuef(),
                                 palette.getSaturationf(),
                                 100);
        
        for (Bloom bloom : model.blooms)
        {
            for (LXPoint spikePoint : bloom.spike.leds)
            {
                LedDistance = new LXVector(spikePoint.x, spikePoint.y, spikePoint.z).dist(bloom.center);
                // the percentage of the total distance this pixel is
                LedPctDistance = 6.28 * (LedDistance/bloom.maxSpikeDistance);
                
                WarpAmount = sin(LedPctDistance * WarpFrequency) * WarpStrength;
                ColorAmount = (.5 + (.5 * sin(Offset + (LedPctDistance * Period))));
                
                ColorLerpValue = clamp(WarpAmount + ColorAmount, 0, 1);
                
                colors[spikePoint.index] = LXColor.lerp(ColorA, ColorB, ColorLerpValue);
            }
            
            for (LXPoint spokePoint : bloom.spokePoints)
            {
                LedDistance = new LXVector(spokePoint.x, spokePoint.y, spokePoint.z).dist(bloom.center);
                LedPctDistance = 6.28 * (LedDistance/bloom.maxSpikeDistance);
                
                
                WarpAmount = sin(LedPctDistance * WarpFrequency) * WarpStrength;
                ColorAmount = (.5 + (.5 * sin(Offset + (LedPctDistance * Period))));
                
                ColorLerpValue = clamp(WarpAmount + ColorAmount, 0, 1);
                
                colors[spokePoint.index] = LXColor.lerp(ColorA, ColorB, ColorLerpValue);
            }
        }
    }
}

@LXCategory("Color")
public class ColorWipe extends RadiaLumiaPattern
{
    
    public final CompoundParameter P_WipeSpeed =
        new CompoundParameter("spd", 5000, .25, 10000);
    
    public final CompoundParameter WipeSharpness = 
        new CompoundParameter("sharp", 1, 1, 100);
    
    public final SinLFO P_WipePosition =
        new SinLFO(-1, 1, P_WipeSpeed);
    
    int CurrentHue;
    int NextHue;
    
    double LastFrameWipeHeight;
    double WipeHeight;
    
    public ColorWipe(LX lx)
    {
        super(lx);
        
        addParameter(P_WipeSpeed);
        addParameter(WipeSharpness);
        startModulator(P_WipePosition);
        
        CurrentHue = 0;
        NextHue = 0;
    }
    
    public void run(double deltaMs)
    {
        WipeHeight = P_WipePosition.getValue() * Config.SCALE;
        
        double Direction = -1;
        if (WipeHeight > LastFrameWipeHeight)
            Direction = 1;
        
        double Exponent = WipeSharpness.getValue();
        float NewHue = palette.getHuef();
        float PaletteSat = palette.getSaturationf();
        
        for (LXPoint p : model.leds)
        {
            double Distance = Direction * (p.y - WipeHeight);
            if (Distance >= Exponent)
                continue;
            
            double WipeInfluence = clamp(1.0 - (Distance / Exponent), 0, 1);
            
            int CurrentColor = colors[p.index];
            
            float CurrentHue = LXColor.h(CurrentColor);
            
            float InterpolatedHue = lerp(CurrentHue, NewHue, (float)WipeInfluence);
            
            colors[p.index] = LXColor.hsb(InterpolatedHue, PaletteSat, 100);
        }
        
        LastFrameWipeHeight = WipeHeight;
    }
}

@LXCategory("Color")
public class ColorLighthouse extends RadiaLumiaPattern
{
    public final CompoundParameter P_RotationSpeed = 
        new CompoundParameter("Spd", 28000, 30000, 1)
        .setDescription("How fast the colors revolve");
    
    public final CompoundParameter P_BeamWidth =
        new CompoundParameter("Wid", 10, 0, 200)
        .setDescription("The width of the beam");
    
    public final CompoundParameter P_Spread =
        new CompoundParameter("Spread", 0, 0, 360);
    
    public final CompoundParameter P_Variance =
        new CompoundParameter("Var", 100, 0, 360);
    
    public final SawLFO P_Rotator =
        new SawLFO(0, 6.14, P_RotationSpeed);
    
    public ColorLighthouse(LX lx)
    {
        super(lx);
        
        addParameter(P_RotationSpeed);
        addParameter(P_BeamWidth);
        addParameter(P_Spread);
        addParameter(P_Variance);
        
        startModulator(P_Rotator);
    }
    
    public void run(double deltaMs)
    {
        // Spatial Parameters
        float Theta = P_Rotator.getValuef(); 
        float SinTheta = sin(Theta);
        float CosTheta = cos(Theta);
        
        LXVector FrontNormal = new LXVector(SinTheta, 0, CosTheta);
        LXVector BackNormal = new LXVector(-SinTheta, 0, -CosTheta);
        
        LXVector FrontCenter = FrontNormal.copy().mult(P_BeamWidth.getValuef());
        LXVector BackCenter = BackNormal.copy().mult(P_BeamWidth.getValuef());
        
        // Color Parameters
        float BaseHue = palette.getHuef();
        float Sat = palette.getSaturationf();;
        float Spread = P_Spread.getValuef();
        float Variance = P_Variance.getValuef();
        
        // Per LED Parameters 
        LXVector PointVector;
        LXVector ToFront, ToBack;
        float PointDotFrontNormal;
        float PointDotBackNormal;
        float AnglePointFront;
        
        for (LXPoint p : model.leds) {
            PointVector = LXPointToVector(p);
            
            ToFront = PointVector.copy().add(FrontCenter);
            ToBack = PointVector.copy().add(BackCenter);
            
            AnglePointFront =  ToFront.copy().normalize().dot(FrontNormal);
            PointDotFrontNormal = AnglePointFront * 1000;
            PointDotBackNormal = ToBack.copy().normalize().dot(BackNormal) * 1000;
            
            PointDotFrontNormal = 1 - constrain(PointDotFrontNormal, 0, 1);
            PointDotBackNormal = 1 - constrain(PointDotBackNormal, 0, 1);
            
            // Hue = Base + Lighthouse Angle Variance (primary) + Distance Based Variance (secondary)
            float Hue = BaseHue + 
                Spread * (PointDotFrontNormal + PointDotBackNormal) +
                (Variance * (sin(AnglePointFront * TWO_PI) + 
                             sin(AnglePointFront * (PI/1.739))));
            
            colors[p.index] = LXColor.hsb(
                Hue,
                Sat,
                100);
        }
    }
}


//rotateAroundBlooms
@LXCategory("Color")
public class Pinwheel extends RadiaLumiaPattern {
    
    public final CompoundParameter period = 
        new CompoundParameter ("delay", 1, 0, 10000);
    
    public final DiscreteParameter step =  
        new DiscreteParameter ("step", 1, 0, 60);
    
    protected int spokeCount = 0;
    protected double timeSinceLastHueChange = 0;
    protected int hueOffset = 0; 
    
    public Pinwheel (LX lx){
        super(lx); 
        
        addParameter(period);
        addParameter(step);
        
    }
    
    public void run (double deltaMs){
        
        timeSinceLastHueChange += deltaMs;
        
        if (timeSinceLastHueChange >= period.getValue()) {
            hueOffset = (hueOffset+step.getValuei())%360;
            timeSinceLastHueChange = 0;
        }
        
        for (Bloom b : model.blooms) { //loops through all blooms
            int hueCount = 0 + hueOffset; 
            for (Bloom.Spoke s : b.spokes){
                for (LXPoint p : s.points){
                    colors[p.index] = LXColor.hsb(hueCount, 100, 100);
                }
                
                hueCount = (hueCount + 60)%360;
                
            }
            
            
        }
    }
}

// RadiaSolid
@LXCategory("Color")
public class RadiaSolid extends RadiaLumiaPattern 
{
    public RadiaSolid (LX lx)
    {
        super(lx);
    }
    
    public void run(double deltaMs)
    {
        int c = palette.getColor();
        
        for (LXPoint light : model.leds) {
            colors[light.index] = c;
        }
        
    }
    
}

@LXCategory("Color")
public class ColorTakeover extends RadiaLumiaPattern
{
    
    public final CompoundParameter P_Period =
        new CompoundParameter("per", 10000, 5000, 60000);
    
    public final CompoundParameter P_DebugProgress =
        new CompoundParameter("dbg", 0, 0, 1);
    
    public final SawLFO P_Progress = 
        new SawLFO(0, 1, P_Period);
    
    public final float TotalTravelDistance;
    
    public int CurrentOriginNode;
    
    public LXVector CurrentOrigin;
    public LXVector CurrentNormal;
    
    public ColorTakeover (LX lx)
    {
        super(lx);
        addParameter(P_Period);
        // TODO(peter): Remove this
        addParameter(P_DebugProgress);
        
        startModulator(P_Progress);
        TotalTravelDistance = Config.SCALE;
        
        CurrentOriginNode = 0;
        Bloom OriginNode = model.blooms.get(CurrentOriginNode);
        
        CurrentOrigin = OriginNode.center.copy();
        CurrentOrigin.add(CurrentOrigin.copy().normalize().mult(OriginNode.maxSpikeDistance));
        
        CurrentNormal = model.blooms.get(CurrentOriginNode).center.copy().mult(-1).normalize();
    }
    
    public void run(double deltaMs)
    {
        float CurrentTravelDistance = P_DebugProgress.getValuef();
        
        LXVector BaseCenter = CurrentOrigin.copy().add(CurrentNormal.mult(CurrentTravelDistance));
        
        for (LXPoint p : model.leds)
        {
            LXVector PointVector = LXPointToVector(p);
            LXVector PlaneLocalVector = PointVector.copy().add(BaseCenter.copy().mult(-1));
            
            float PointDotNormal = PlaneLocalVector.dot(CurrentNormal);
            PointDotNormal = constrain(PointDotNormal, 0, 1);
            
            colors[p.index] = LXColor.hsb(0, 0, PointDotNormal * 100);
        }
    }
}

@LXCategory("Color")
public class ContrastNoise extends RadiaLumiaPattern 
{
    public final CompoundParameter P_ContrastAngle =
      new CompoundParameter("HueAngle", 90, 0, 360);
    
    public final CompoundParameter P_ColorRange =
      new CompoundParameter("Range", 30, 0, 360);
    
    public final CompoundParameter P_BaseScale = 
      new CompoundParameter("Base Scale", 2.5, 1, 10);
    
    public final CompoundParameter P_BaseSpeed = (CompoundParameter)
      new CompoundParameter("Base Speed", .5, -1, 1)
      .setPolarity(LXParameter.Polarity.BIPOLAR);
    
    public final CompoundParameter P_ContrastPresence =
      new CompoundParameter("Contrast", 0, 0, 1);
      
    public final CompoundParameter P_ContrastScale =
      new CompoundParameter("ConScale", 2.5, 1, 10);
    
    public final CompoundParameter P_ContrastSpeed = (CompoundParameter)
      new CompoundParameter("ConSpeed", .5, -1, 1)
      .setPolarity(LXParameter.Polarity.BIPOLAR);
      
    float Base_NoiseBasis = 0f;
    float Contrast_NoiseBasis = 0f;
    
    public ContrastNoise (LX lx)
    {
        super(lx);
        addParameter(P_ContrastAngle);
        addParameter(P_ColorRange);
        
        addParameter(P_BaseScale);
        addParameter(P_BaseSpeed);
        
        addParameter(P_ContrastPresence);
        addParameter(P_ContrastScale);
        addParameter(P_ContrastSpeed);
    }
    
    final float MOTION_MOD = .001;
    
    public void run (double deltaMs)
    {
        Base_NoiseBasis += deltaMs * MOTION_MOD * P_BaseSpeed.getValuef();
        Contrast_NoiseBasis += deltaMs * MOTION_MOD * P_ContrastSpeed.getValuef();
        
        float BaseHue_Center = palette.getHuef();
        float ContrastHue_Center = BaseHue_Center + P_ContrastAngle.getValuef();
        
        float Adjusted_BaseHue_StartRange = BaseHue_Center - P_ColorRange.getValuef();
        float Adjusted_BaseHue_EndRange = BaseHue_Center + P_ColorRange.getValuef();
        if (Adjusted_BaseHue_StartRange > Adjusted_BaseHue_EndRange)
            Adjusted_BaseHue_StartRange -= 360f;
        
        float Adjusted_ContrastHue_StartRange = ContrastHue_Center - P_ColorRange.getValuef();
        float Adjusted_ContrastHue_EndRange = ContrastHue_Center + P_ColorRange.getValuef();
        if (Adjusted_ContrastHue_StartRange > Adjusted_ContrastHue_EndRange)
            Adjusted_ContrastHue_StartRange -= 360f;
            
        float BaseScale = P_BaseScale.getValuef();
        float ContrastScale = P_ContrastScale.getValuef();
        
        float ContrastMinRange = 1f - P_ContrastPresence.getValuef();
        float ContrastMaxRange = 1f;
            
        for (LXPoint p : model.leds)
        {
            float presence = 0f;
            float xBase = (p.xn * ContrastScale) + p.zn + Contrast_NoiseBasis;
            float yBase = (p.yn * ContrastScale) + p.xn + Contrast_NoiseBasis;
            float zBase = (p.zn * ContrastScale) + p.zn + Contrast_NoiseBasis;

            presence = noise(xBase + 1f * ContrastScale, yBase + 1f * ContrastScale, zBase + 1f * ContrastScale);
            presence = sin(presence);
            
            if (presence < ContrastMinRange || presence > ContrastMaxRange)
            {
                float nv = noise(
                  (p.xn * BaseScale) + p.xn + Base_NoiseBasis,
                  (p.yn * BaseScale) + p.yn + Base_NoiseBasis, 
                  (p.zn * BaseScale) + p.zn + Base_NoiseBasis
                ); 
                nv = sin(nv);
                nv *= nv;
                
                float Hue = lerp(Adjusted_BaseHue_StartRange, Adjusted_BaseHue_EndRange, nv);
                colors[p.index] = LXColor.lerp(colors[p.index], LXColor.hsb(Hue, 100, 100), presence);
            }
            else
            {
                float nv = noise(
                  (p.xn * ContrastScale) + p.xn + Contrast_NoiseBasis,
                  (p.yn * ContrastScale) + p.yn + Contrast_NoiseBasis, 
                  (p.zn * ContrastScale) + p.zn + Contrast_NoiseBasis
                ); 
                nv = sin(nv);
                nv *= nv;
                
                float Hue = lerp(Adjusted_ContrastHue_StartRange, Adjusted_ContrastHue_EndRange, nv);
                colors[p.index] = LXColor.lerp(colors[p.index], LXColor.hsb(Hue, 100, 100), presence);
            }
        }
    }
}

@LXCategory("Color")
public class UmbrellaHighlights extends RadiaLumiaPattern
{
    public final CompoundParameter P_ContrastAmt =
      new CompoundParameter("Contrast", 90, 0, 360);
    
    public final BooleanParameter P_WhiteAround =
      new BooleanParameter("White", false);
    
    public UmbrellaHighlights (LX lx)
    {
      super(lx);
      addParameter(P_ContrastAmt);
      addParameter(P_WhiteAround);
    }
    
    public void run (double deltaMs)
    {
       UpdateUmbrellaMask();
       
       float ContrastOffsetAngle = P_ContrastAmt.getValuef();
       
       float ContrastHue = palette.getHuef() + ContrastOffsetAngle;
       int ContrastColor = LXColor.hsb(ContrastHue, 100, 100);
       if (P_WhiteAround.getValueb())
         ContrastColor = LXColor.WHITE;
       
       for (LXPoint p : model.leds)
       {
          if (POINT_COVEREDBYUMBRELLA[p.index])
          {
             colors[p.index] = LXColor.hsb(palette.getHuef(), 100, 100);
          }
          else
          {
             colors[p.index] = ContrastColor;
          }
       }
    }
}


@LXCategory("Color")
public class BattlingColors extends RadiaLumiaPattern
{
  
   public final CompoundParameter P_ContrastAngle =
       new CompoundParameter("Contrast", 90, 0, 360);
       
   public final CompoundParameter P_WaveWidth =
       new CompoundParameter("Width", .25, 0, 2);
   
   public final CompoundParameter P_WavePeriod =
       new CompoundParameter("Per", 4, 0, 7);
       
   public final CompoundParameter P_WaveXShift = 
       new CompoundParameter("XShft", .5, 0, 2);
       
   public final CompoundParameter P_WaveSpeed = 
       new CompoundParameter("Speed", 5 * SECONDS, 0, 30 * SECONDS);
       
   public final SawLFO P_WaveOffset =
       new SawLFO(0, TWO_PI, P_WaveSpeed);
       
   public BattlingColors(LX lx)
   {
       super(lx);
       addParameter(P_ContrastAngle);
       addParameter(P_WaveWidth);
       addParameter(P_WavePeriod);
       addParameter(P_WaveXShift);
       addParameter(P_WaveSpeed);
       
       startModulator(P_WaveOffset);
   }
   
   public void run (double deltaMs)
   {
       float WaveOffset = P_WaveOffset.getValuef();
       float WaveWidth = P_WaveWidth.getValuef();
       float WavePeriod = P_WavePeriod.getValuef();
       float WaveXShift = P_WaveXShift.getValuef();
       
       float HueA = palette.getHuef();
       float HueB = P_ContrastAngle.getValuef() + HueA;
       
       int ColorA = LXColor.hsb(HueA, 100, 100);
       int ColorB = LXColor.hsb(HueB, 100, 100);
       
       for (LXPoint p : model.leds)
       {
           float SinAtY = sin((p.yn + WaveOffset) * WavePeriod) * WaveWidth;
           if (p.xn - WaveXShift < SinAtY)
           {
              colors[p.index] = ColorA;
           }
           else
           {
              colors[p.index] = ColorB;
           }
       }
   }
}
