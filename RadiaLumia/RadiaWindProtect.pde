// Pattern: RadiaWindProtect
//
// Controlled by output from an anemometer that triggers the entire sphere to contract
// its shells in an elegant fashion whenever the wind picks up.
//

@LXCategory("Umbrella")
public class RadiaWindProtect extends UmbrellaEffect {
	
    // more than this and we'll
    private final static float CLOSE_THRESHOLD = 0.75; 	
	
    // input from the anemometer sent to us in the range of 0 (no wind) to 1 (time to freak out)
    public final CompoundParameter SensorRef_WindState;
    
    private MovingAverage windAvg;
    
	public RadiaWindProtect(LX lx) {
        super(lx);
        // println("[ RadiaWindProtect ] | Constructor");
        WindProtect_Singleton = this;
        windAvg = new MovingAverage(100);
        SensorRef_WindState = sensors.SensorValueCache.get(Sensors.SENSOR_ADDRESS_ANEMOMETER);
	}
    
	public void run (double deltaMs, double amount) {
		float windState = (float) windAvg.NextVal(this.SensorRef_WindState.getValuef());
		
		// contract the shells if windy
		if (windState > CLOSE_THRESHOLD) {
    println(windState);
            for (Bloom b : model.blooms) {
				setUmbrella(b, 0);
            }
        }
        // otherwise let the other animation channels do their thing
	}
}
