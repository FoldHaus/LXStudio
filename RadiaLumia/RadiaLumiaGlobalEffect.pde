// SingletonUmbrellaUpdater
// Added to the Main Channel by the first UmbrellaPattern created
// At the end of every frame, goes through and calls UpdateUmbrellas for each
// umbrella
public class SingletonUmbrellaUpdater extends LXModelEffect<Model> {
  
  public final CompoundParameter underUmbrella_Brightness = 
    new CompoundParameter ("umbB", 100, 0, 100)
    .setDescription("The brightness of the lights covered by the umbrella");

  public final CompoundParameter openAir_Brightness = 
    new CompoundParameter ("oaB", 0, 0, 100)
    .setDescription("The brightness of the lights open to the air.");

  public SingletonUmbrellaUpdater (LX lx) {
   super(lx);
   
   addParameter(underUmbrella_Brightness);
   addParameter(openAir_Brightness);
   
   umbrellaUpdater = this;
   this.enable();
  }
  
  public void run (double deltaMs, double enabledAmount) {
    for (Bloom b : model.blooms) {
      b.umbrella.UpdateUmbrella(deltaMs);
    }

    maskUncoveredLights(deltaMs, enabledAmount);
  }

  public void maskUncoveredLights (double deltaMs, double enabledAmount) {
    
    float bloom_umbrellaBottomPosition, bloom_umbrellaTopPosition;
    float spike_coveredRange_bottomPosition, spike_coveredRange_topPosition;
    float spoke_coveredRange_bottomPosition, spoke_coveredRange_topPosition;

    float point_distance, point_percentTotalDistance, onMask;

    float[] spike_coveredRange_top = {.5, .2};
    float[] spike_coveredRange_bottom = {0, 0};
    
    float[] spoke_coveredRange_top = {.2, 1};
    float[] spoke_coveredRange_bottom = {0, 0};

    for (Bloom b : model.blooms) {
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

      
      /*
      spike_coveredRange_bottomPosition = ((float)b.umbrella.GetPercentClosed() * spike_coveredRange_bottom[0]) + ((1f - (float)b.umbrella.GetPercentClosed()) * spike_coveredRange_bottom[1]);
      spike_coveredRange_topPosition = ((float)b.umbrella.GetPercentClosed() * spike_coveredRange_top[0]) + ((1f - (float)b.umbrella.GetPercentClosed()) * spike_coveredRange_top[1]);
      
      spoke_coveredRange_bottomPosition = ((float)b.umbrella.GetPercentClosed() * spoke_coveredRange_bottom[0]) + ((1f - (float)b.umbrella.GetPercentClosed()) * spoke_coveredRange_bottom[1]);
      spoke_coveredRange_topPosition = ((float)b.umbrella.GetPercentClosed() * spoke_coveredRange_top[0]) + ((1f - (float)b.umbrella.GetPercentClosed()) * spoke_coveredRange_top[1]);
      
      
      // Mask the spike
      for (LXPoint point : b.spike.getPoints()) {
        point_distance = new LXVector(point.x, point.y, point.z).dist(b.center);
        point_percentTotalDistance = (point_distance / b.maxSpikeDistance);
        
        onMask = (int)this.underUmbrella_Brightness.getValue();
        if (point_percentTotalDistance < spike_coveredRange_bottomPosition || point_percentTotalDistance > spike_coveredRange_topPosition) {
          onMask = (int)this.openAir_Brightness.getValue();
        }

        colors[point.index] = LXColor.multiply(LXColor.hsb(0, 0, onMask), colors[point.index]);
      }

      for (LXPoint point : b.spokePoints) {
        point_distance = new LXVector(point.x, point.y, point.z).dist(b.center);
        point_percentTotalDistance = (point_distance / b.maxSpokesDistance);
        
        onMask = (int)this.underUmbrella_Brightness.getValue();
        if (point_percentTotalDistance < spoke_coveredRange_bottomPosition || point_percentTotalDistance > spoke_coveredRange_topPosition) {
          onMask = (int)this.openAir_Brightness.getValue();
        }

        colors[point.index] = LXColor.multiply(LXColor.hsb(0, 0, onMask), colors[point.index]);
      }

      */
    }
  }
}


public class UmbrellaMask extends LXModelEffect<Model> {

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
