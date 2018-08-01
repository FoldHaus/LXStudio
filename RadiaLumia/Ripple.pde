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
    
    
    for (Bloom bloom: model.blooms) {

      LXVector bloomCenter = bloom.center;

      for (LXPoint led : bloom.spike.leds) {
        LXVector ledVector = LXPointToVector(led);

        dist_from_center_percent = ledVector.dist(bloomCenter) / (bloom.maxSpokesDistance);

        sinValue = (double)(sin(off + per * dist_from_center_percent));
            
        sinValue = 0.5 + 0.5 * sinValue;
        brightness_value = 100 * sinValue;      

        colors[led.index] = LXColor.hsb(360, 100, brightness_value);
      }

        for (Bloom.Spoke spoke : bloom.spokes) {
          for (LXPoint light : spoke.points) {
            
            LXVector lightVector = LXPointToVector(light);


            dist_from_center_percent = lightVector.dist(bloomCenter) / (bloom.maxSpokesDistance);

            sinValue = (double)(sin(off + per * dist_from_center_percent));
            
            sinValue = 0.5 + 0.5 * sinValue;
            brightness_value = 100 * sinValue;          
            colors[light.index] = LXColor.hsb(360, 100, brightness_value);
          }
        }
      
    }
  }
}