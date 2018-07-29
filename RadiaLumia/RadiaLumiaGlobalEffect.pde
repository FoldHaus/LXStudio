@LXCategory("Umbrella")
public class ColorBalance extends UmbrellaEffect {
    
    //  public static ColorBalance _singleton;
    
    public final CompoundParameter underUmbrella_Brightness = 
        new CompoundParameter ("umbB", 100, 0, 100)
        .setDescription("The brightness of the lights covered by the umbrella");
    
    public final CompoundParameter openAir_Brightness = 
        new CompoundParameter ("oaB", 0, 0, 100)
        .setDescription("The brightness of the lights open to the air.");
    
    public final CompoundParameter heart_Brightness =
        new CompoundParameter ("heart", 0, 0, 100)
        .setDescription("The brightness of the lights in the heart");
    
    public final CompoundParameter pinSpot_Brightness =
        new CompoundParameter ("pin", 0, 0, 100)
        .setDescription("The brightness of the pin spot lights");
    
    public ColorBalance (LX lx) {
        super(lx);
        
        addParameter(underUmbrella_Brightness);
        addParameter(openAir_Brightness);
        addParameter(heart_Brightness);
        addParameter(pinSpot_Brightness);
        
        this.enable();
    }
    
    public void run (double deltaMs, double enabledAmount) {
        maskUncoveredLights(deltaMs, enabledAmount);
    }
    
    public void maskUncoveredLights (double deltaMs, double enabledAmount) {
        
        UpdateUmbrellaMask();
        
        int heart_brightness = (int)(heart_Brightness.getValue());
        int pinSpot_brightness = (int)(pinSpot_Brightness.getValue());
        
        float openAirBrightness = (float)this.openAir_Brightness.getValue();
        float underUmbrellaBrightness = (float)this.underUmbrella_Brightness.getValue();
        
        boolean bloom_debug = false;
        
        for (LXPoint p : model.heart.points) {
            int curr_color = colors[p.index];
            colors[p.index] = LXColor.hsb(LXColor.h(curr_color), LXColor.s(curr_color), heart_brightness);
        }
        
        int underUmbrellaMultiplyBy = LXColor.hsb(0, 0, underUmbrellaBrightness);
        int openAirMultiplyBy = LXColor.hsb(0, 0, openAirBrightness);
        
        for (Bloom b : model.blooms) {
            for (LXPoint p : b.leds) {
                if (POINT_COVEREDBYUMBRELLA[p.index]) {
                    colors[p.index] = LXColor.multiply(underUmbrellaMultiplyBy, colors[p.index]);
                }else{
                    colors[p.index] = LXColor.multiply(openAirMultiplyBy, colors[p.index]);
                }
            }
        }
        
        UmbrellaMaskEndFrame();
    }  
}


public static int ENTRANCE_BLOOM_ONE = 3;
public static int ENTRANCE_BLOOM_TWO = 28;
public static int ENTRANCE_BLOOM_THREE = 27;

// The effect for controlling the entrance to the Radia Lumia.
@LXCategory("Umbrella")
public class RadiaEntranceEffect extends UmbrellaEffect {
    
    public final CompoundParameter SensorRef_Ladder;
    /*= 
        new CompoundParameter ("lcv", 0, 0, 1)
        .setDescription("The value being sent over from the ladder load cells");
    */
    
    public final BooleanParameter overrideEntrance = 
        new BooleanParameter ("ovr")
        .setDescription("Should the entrance always override the umbrella position or only when it needs to open");
    
    public RadiaEntranceEffect (LX lx) {
        super(lx);
        
        addParameter(overrideEntrance);
        
        SensorRef_Ladder = sensors.SensorValueCache.get(Sensors.SENSOR_ADDRESS_LADDER);
    }
    
    public void run (double deltaMs, double enabledAmount) {
        
        double openClosedValue = SensorRef_Ladder.getValue();
        
        if (openClosedValue > 0.0 || overrideEntrance.getValueb())
        {
            // Get the entrance blooms
            Bloom bloomOne = model.blooms.get(ENTRANCE_BLOOM_ONE);
            Bloom bloomTwo = model.blooms.get(ENTRANCE_BLOOM_TWO);
            Bloom bloomThree = model.blooms.get(ENTRANCE_BLOOM_THREE);
            
            // Generate Percent Closed
            setUmbrella(bloomOne, openClosedValue);
            setUmbrella(bloomTwo, openClosedValue);
            setUmbrella(bloomThree, openClosedValue);
        }
    }
}