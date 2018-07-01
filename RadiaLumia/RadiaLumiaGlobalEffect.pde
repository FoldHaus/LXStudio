@LXCategory("Umbrella")
public class UmbrellaMask extends UmbrellaEffect {
  
  //  public static UmbrellaMask _singleton;
  
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

  public UmbrellaMask (LX lx) {
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
