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
    
    public final SawLFO Progress =
        new SawLFO(0, 360, P_MotionSpeed);
    
    public RadialGradient (LX lx)
    {
        super(lx);
        
        addParameter(P_MotionSpeed);
        addParameter(P_ColorPeriod);
        
        startModulator(Progress);
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