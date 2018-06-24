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
    
    int heart_brightness = (int)(heart_Brightness.getValue());
    int pinSpot_brightness = (int)(pinSpot_Brightness.getValue());

    float openAirBrightness = (float)this.openAir_Brightness.getValue();
    float underUmbrellaBrightness = (float)this.underUmbrella_Brightness.getValue();

    boolean bloom_debug = false;
    
    for (LXPoint p : model.heart.points) {
      int curr_color = colors[p.index];
      
      colors[p.index] = LXColor.hsb(LXColor.h(curr_color), LXColor.s(curr_color), heart_brightness);
    }
        
    for (Bloom b : model.blooms) {
      // TODO: GetSpikePointsUnderUmbrella constructs a new dynamic list every time,
      // this is too costly to do in a loop on every iteration
      List<LXPoint> spikePoints_openAir = GetSpikePointsUnderUmbrella(b, true);
      List<LXPoint> spikePoints_underUmbrella = GetSpikePointsUnderUmbrella(b, false);

      List<LXPoint> spokePoints_openAir = GetSpokePointsUnderUmbrella(b, true);
      List<LXPoint> spokePoints_underUmbrella = GetSpokePointsUnderUmbrella(b, false);
      
      for (LXPoint p : spikePoints_openAir) {
        colors[p.index] = LXColor.multiply(LXColor.hsb(0, 0, openAirBrightness), colors[p.index]);
      }

      for (LXPoint p : spikePoints_underUmbrella) {
        colors[p.index] = LXColor.multiply(LXColor.hsb(0, 0, underUmbrellaBrightness), colors[p.index]);
      }
      
      for (LXPoint p : spokePoints_openAir) {
        colors[p.index] = LXColor.multiply(LXColor.hsb(0, 0, openAirBrightness), colors[p.index]);
      }

      for (LXPoint p : spokePoints_underUmbrella) {
        colors[p.index] = LXColor.multiply(LXColor.hsb(0, 0, underUmbrellaBrightness), colors[p.index]);
      }
      
      colors[b.spike.pinSpot.index] = LXColor.multiply(LXColor.hsb(0, 0, pinSpot_brightness), colors[b.spike.pinSpot.index]);
      
      
      if (!bloom_debug) {
        int r = LXColor.red(colors[b.spike.pinSpot.index]);
        int g = LXColor.green(colors[b.spike.pinSpot.index]);
        int bl = LXColor.blue(colors[b.spike.pinSpot.index]);
        println("Pinspot Index:", b.spike.pinSpot.index);
        println("Pinspot Color:", r, g, bl);
        println("Pinspot Pos:", b.spike.pinSpot.x, b.spike.pinSpot.y, b.spike.pinSpot.z);
        bloom_debug = true;
      }

    }
  }  
}
