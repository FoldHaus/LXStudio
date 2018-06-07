@LXCategory("Umbrella")
public class UmbrellaMask extends UmbrellaEffect {

  public final CompoundParameter underUmbrella_Brightness = 
    new CompoundParameter ("umbB", 100, 0, 100)
    .setDescription("The brightness of the lights covered by the umbrella");

  public final CompoundParameter openAir_Brightness = 
    new CompoundParameter ("oaB", 0, 0, 100)
    .setDescription("The brightness of the lights open to the air.");

  public UmbrellaMask (LX lx) {
   super(lx);
   
   addParameter(underUmbrella_Brightness);
   addParameter(openAir_Brightness);

   this.enable();
  }
  
  public void run (double deltaMs, double enabledAmount) {
    maskUncoveredLights(deltaMs, enabledAmount);
  }

  public void maskUncoveredLights (double deltaMs, double enabledAmount) {
    
    for (Bloom b : model.blooms) {
      // TODO: GetSpikePointsUnderUmbrella constructs a new dynamic list every time,
      // this is too costly to do in a loop on every iteration
      List<LXPoint> spikePoints_openAir = GetSpikePointsUnderUmbrella(b, true);
      List<LXPoint> spikePoints_underUmbrella = GetSpikePointsUnderUmbrella(b, false);

      List<LXPoint> spokePoints_openAir = GetSpokePointsUnderUmbrella(b, true);
      List<LXPoint> spokePoints_underUmbrella = GetSpokePointsUnderUmbrella(b, false);

      float openAirBrightness = (float)this.openAir_Brightness.getValue();
      float underUmbrellaBrightness = (float)this.underUmbrella_Brightness.getValue();
      
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
    }
  }  
}
