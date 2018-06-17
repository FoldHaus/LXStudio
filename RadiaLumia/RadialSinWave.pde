public class RadialSinWave extends RadiaLumiaPattern {
  
  public final CompoundParameter period =
    new CompoundParameter("per", .05, 0, .5)
    .setDescription("The period of the sin wave");
  
  public final CompoundParameter offset = 
    new CompoundParameter("off", .5, 0, 1000)
    .setDescription("Current offset of the sin wave");

  public final CompoundParameter width = 
    new CompoundParameter("wid", .05, 0, 1)
    .setDescription("Width of the sin wave");

  public final CompoundParameter sampleSpacing = 
    new CompoundParameter("spc", .2, 0.0, 1.0)
    .setDescription("Spacing between samples of the sin wave, in percent of 2*PI");

  public RadialSinWave(LX lx){
    super(lx);
    addParameter(period);
    addParameter(offset);
    addParameter(width);
    addParameter(sampleSpacing);
  }

  public void run(double deltaMs) {
    
    double bloomAcc = 0;
    double x = 0.0;
    double sinValue = 0.0;

    double per = period.getValue();
    double off = offset.getValue();
    double wid = width.getValue();
    double spc = sampleSpacing.getValue();

    double light_percent = 0.0;
    double brightness_value = 0.0;
    
    for (Bloom bloom: model.blooms) {
      bloomAcc += 1;
      x = 0.0;
      for (Bloom.Spoke spoke : bloom.spokes) {
        x += bloomAcc + ((2.0 * 3.14) * spc);
        sinValue = (double)(.5 + .5 * sin((float)(per * (off + x))));

        for (LXPoint light : spoke.points) {
          
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
