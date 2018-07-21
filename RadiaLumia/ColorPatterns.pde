@LXCategory("Color")
public class ColorSpheres extends RadiaLumiaPattern {
    
    public final CompoundParameter sphereBaseSize = 
        new CompoundParameter("size", 1, 0, 350);
    
    public final CompoundParameter deltaMag =
        new CompoundParameter("dmag", 0, 0, 300);
    
    public final CompoundParameter offset =
        new CompoundParameter("off", 0, 0, 300);
    
    public final ColorParameter colorA =
        new ColorParameter("A");
    
    
    
    public ColorSpheres (LX lx) {
        super(lx);
        addParameter(sphereBaseSize);
        addParameter(deltaMag);
        addParameter(offset);
        addParameter(colorA);
    }
    
    public void run (double deltaMs) {
        
        double diameter = sphereBaseSize.getValue();
        float theta = (float)(offset.getValue());
        float delta_mag = (float)(deltaMag.getValue());
        
        LXVector sphereA_pos = new LXVector(sin(theta), sin(.835 * (theta + .3251)), cos(theta)).normalize().mult(delta_mag);
        LXVector sphereB_pos = new LXVector(sin(-theta + .3), cos(.831 * (theta + .3415) + .3), cos(-theta + .3)).normalize().mult(delta_mag);
        
        double a_distance = 0;
        double a_pct_diameter = 0;
        double b_distance = 0;
        double b_pct_diameter = 0;
        
        LXVector light_pos;
        
        int hueA = (int)(sin(theta * .1) * 360);
        int hueB = (int)(sin(theta * .162 + .138) * 360);
        int hueC = (int)(sin(theta - .183) * 360);
        
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
        
        for (Bloom bloom : model.blooms)
        {
            for (LXPoint spikePoint : bloom.spike.leds)
            {
                LedDistance = new LXVector(spikePoint.x, spikePoint.y, spikePoint.z).dist(bloom.center);
                // the percentage of the total distance this pixel is
                LedPctDistance = (LedDistance/bloom.maxSpikeDistance);
                
                int Hue = (int)(360 * (LedPctDistance * ColorPeriod) + ColorOffset) % 360;
                colors[spikePoint.index] = LXColor.hsb(Hue, 100, 100);
            }
            
            for (LXPoint spokePoint : bloom.spokePoints)
            {
                LedDistance = new LXVector(spokePoint.x, spokePoint.y, spokePoint.z).dist(bloom.center);
                LedPctDistance = (LedDistance/bloom.maxSpikeDistance);
                
                int Hue = (int)(360 * (LedPctDistance * ColorPeriod) + ColorOffset) % 360;
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
    
    public final ColorParameter P_ColorA =
        new ColorParameter("A", LXColor.hsb(100, 100, 100));
    
    public final ColorParameter P_ColorB = 
        new ColorParameter("B", LXColor.hsb(200, 100, 100));
    
    public final SawLFO Progress =
        new SawLFO(0, 6, P_MotionSpeed);
    
    public RadialStripes (LX lx)
    {
        super(lx);
        
        addParameter(P_MotionSpeed);
        addParameter(P_ColorPeriod);
        addParameter(P_Warp);
        addParameter(P_WarpFrequency);
        
        addParameter(P_ColorA);
        addParameter(P_ColorB);
        
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
        
        int ColorA = P_ColorA.getColor();
        int ColorB = P_ColorB.getColor();
        
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
    
    public final CompoundParameter HueChangeFrequency =
        new CompoundParameter("d freq", 5, .25, 10000);
    
    public final CompoundParameter WipeSpeed =
        new CompoundParameter("spd", 5, .25, 10000);
    
    public final CompoundParameter WipeSharpness = 
        new CompoundParameter("sharp", 1, 1, 100);
    
    public final CompoundParameter P_WipeHeight =
        new CompoundParameter("d", 0, 0, 1);
    
    int CurrentHue;
    int NextHue;
    
    double TimeSinceLastWipe;
    double WipeHeight;
    
    public ColorWipe(LX lx)
    {
        super(lx);
        
        addParameter(HueChangeFrequency);
        addParameter(WipeSpeed);
        addParameter(WipeSharpness);
        
        addParameter(P_WipeHeight);
        
        CurrentHue = 0;
        NextHue = 0;
    }
    
    public void run(double deltaMs)
    {
        TimeSinceLastWipe += deltaMs;
        if (TimeSinceLastWipe > HueChangeFrequency.getValue())
        {
            // NOTE(peter): Wipe Completed
            if (TimeSinceLastWipe > HueChangeFrequency.getValue() + WipeSpeed.getValue())
            {
                TimeSinceLastWipe = 0;
            }else{
                
            }
        }
        
        WipeHeight = P_WipeHeight.getValue() * 150;
        
        double Exponent = WipeSharpness.getValue();
        
        for (LXPoint p : model.leds)
        {
            double Distance = abs(p.y - WipeHeight);
            double WipeInfluence = clamp(1.0 - (Distance / Exponent), 0, 1);
            
            colors[p.index] = LXColor.hsb(0, 0, WipeInfluence * 100);
        }
    }
}