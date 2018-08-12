
@LXCategory("Pulley")
public class LoadingWipe extends RadiaLumiaPattern {
  
    public final CompoundParameter pul1 =
        new CompoundParameter("pul1", 0.2, 0, 1)
        .setDescription("The pulley strength");


    public final CompoundParameter pul2 =
        new CompoundParameter("pul2", 0.2, 0, 1)
        .setDescription("The pulley strength");


    public final CompoundParameter pul3 =
        new CompoundParameter("pul3", 0.2, 0, 1)
        .setDescription("The pulley strength");

    public final BooleanParameter liveSensor =
        new BooleanParameter("live")
        .setDescription("Use sensor cache form OSC");


    public CompoundParameter SensorRef_PullState1;
    public CompoundParameter SensorRef_PullState2;
    public CompoundParameter SensorRef_PullState3;

    // what's stored at pulley event
    class pulleyEvent {
        public double force;
        public String time; // TODO: convert to java date format object

        public pulleyEvent(double force, String time) {
            this.force = force;
            this.time = time;
        }
    }

    class pulley {
        public double currForce;
        public int bloomId;
        public List<pulleyEvent> pulleyHistory; //TODO: this might be a file output stream for performance reason

        // constructor
        public pulley(int bloomId) {
            this.currForce = 0.0;
            this.bloomId = bloomId;
            this.pulleyHistory = new ArrayList<pulleyEvent>();
        }

        // add event
        public void addEvent(double force, String time) {
            pulleyEvent p = new pulleyEvent(force, time);
            pulleyHistory.add(p);
        }

    }


    private pulley pulley1;
    private pulley pulley2;
    private pulley pulley3;
    private int avgSize = 50;
    private MovingAverage pullAvg1 = new MovingAverage(avgSize);
    private MovingAverage pullAvg2 = new MovingAverage(avgSize);
    private MovingAverage pullAvg3 = new MovingAverage(avgSize);
    
    public LoadingWipe(LX lx){
        super(lx);
        addParameter(this.pul1);
        addParameter(this.pul2);
        addParameter(this.pul3);
        addParameter(this.liveSensor);

        int bloomId1 = 35;
        int bloomId2 = 22;
        int bloomId3 = 36;

        pulley1 = new pulley(bloomId1);
        pulley2 = new pulley(bloomId2);
        pulley3 = new pulley(bloomId3);

        SensorRef_PullState1 = sensors.SensorValueCache.get(Sensors.SENSOR_ADDRESS_PULLEY_ONE);
        SensorRef_PullState2 = sensors.SensorValueCache.get(Sensors.SENSOR_ADDRESS_PULLEY_TWO);
        SensorRef_PullState3 = sensors.SensorValueCache.get(Sensors.SENSOR_ADDRESS_PULLEY_THREE);

    }


    public void run(double deltaMs) {



        boolean live = liveSensor.getValueb();

        double pullStrength1, pullStrength2, pullStrength3;

        // double curr, prev1, prev2, prev3 = 0.0;

        if (live) {
            // curr = this.SensorRef_PullState1.getValue();
            // if (curr != prev1) {
            //     pullStrength1 = pullAvg1.NextVal(curr); 
            //     prev1 = curr;
            // }
            
            pullStrength1 = pullAvg1.NextVal(this.SensorRef_PullState1.getValue());
            pullStrength2 = pullAvg2.NextVal(this.SensorRef_PullState2.getValue());
            pullStrength3 = pullAvg3.NextVal(this.SensorRef_PullState3.getValue());

        } else {
            pullStrength1 = pullAvg1.NextVal(this.pul1.getValue());
            pullStrength2 = pullAvg2.NextVal(this.pul2.getValue());
            pullStrength3 = pullAvg3.NextVal(this.pul3.getValue());
        }

        int maxDistance = 500;

        double totalStrength = pullStrength3 + pullStrength2 + pullStrength1;
        double threshold =  (totalStrength / 3) * maxDistance;


        LXVector centerVector1 = model.blooms.get(pulley1.bloomId).center;
        LXVector centerVector2 = model.blooms.get(pulley2.bloomId).center;
        LXVector centerVector3 = model.blooms.get(pulley3.bloomId).center;



        double tempDist1, tempDist2, tempDist3;

        for (LXPoint led : model.leds) {
            LXVector ledVector = LXPointToVector(led);

            tempDist1 = centerVector1.dist(ledVector);
            tempDist2 = centerVector2.dist(ledVector);
            tempDist3 = centerVector3.dist(ledVector);

            if (tempDist1 < pullStrength1 * 500) {
                colors[led.index] = LXColor.hsb(100, 100, 100);
            }
            else if (tempDist2 < pullStrength2 * 500) {
                colors[led.index] = LXColor.hsb(200, 100, 100);
            }
            else if (tempDist3 < pullStrength3 * 500) {
                colors[led.index] = LXColor.hsb(300, 100, 100);
            }
            else {
                colors[led.index] = LXColor.hsb(0, 0, 0);
            }
        }


    }
}


public class MovingAverage {
    private double[] arr;
    int ptr, n;
    private double sum;

    public MovingAverage(int size) {
        arr = new double[size];
        ptr = 0;
        sum = 0;
    }

    public double NextVal(double val) {
        if (n < arr.length) {
            n++;
        }

        sum = sum - arr[ptr];
        sum = sum + val;
        arr[ptr] = val;
        ptr = (ptr + 1) % arr.length;
        return (double)sum/n;
    }
}