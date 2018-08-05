// Pattern: RadiaWindProtect
//
// Controlled by output from an anemometer that triggers the entire sphere to contract
// its shells in an elegant fashion whenever the wind picks up.
//

@LXCategory("Umbrella")
public class RadiaWindProtect extends UmbrellaEffect {
	
    // more than this and we'll
    private final static float CLOSE_THRESHOLD = 0.5; 	
	
    // input from the anemometer sent to us in the range of 0 (no wind) to 1 (time to freak out)
    public CompoundParameter SensorRef_WindState;
    
	// how fast the entire sphere will close in seconds -- NATHALIE: currently unused
	public final CompoundParameter patternSpeed = 
        new CompoundParameter ("speed", 5000, 30000, 0).setDescription("How quickly in milliseconds the animation flows through the sphere");
    
	// value determines the vertical cross section of shells being affected
	public final SinLFO waveValue =
        new SinLFO(0, 1, patternSpeed);
    
	public RadiaWindProtect(LX lx) {
        super(lx);
        WindProtect_Singleton = this;
        
        //addParameter(windState);
        addParameter(patternSpeed);
		startModulator(waveValue);
        
        SensorRef_WindState = sensors.SensorValueCache.get(Sensors.SENSOR_ADDRESS_ANEMOMETER);
	}
    
	public void run (double deltaMs, double amount) {
		float windState = this.SensorRef_WindState.getValuef();
		
		// contract the shells if windy
		if (windState > CLOSE_THRESHOLD) {
            for (Bloom b : model.blooms) {
				setUmbrella(b, 1);
            }
        }
        // otherwise let the other animation channels do their thing
	}
}
