
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
    
    public LoadingWipe(LX lx){
        super(lx);
        addParameter(this.pul1);
        addParameter(this.pul2);
        addParameter(this.pul3);

        int bloomId1 = 35;
        int bloomId2 = 22;
        int bloomId3 = 36;

        pulley1 = new pulley(bloomId1);
        pulley2 = new pulley(bloomId2);
        pulley3 = new pulley(bloomId3);
    }


    public void run(double deltaMs) {
        double pullStrength1 = this.pul1.getValue();
        double pullStrength2 = this.pul2.getValue();
        double pullStrength3 = this.pul3.getValue();



        int maxDistance = 500;

        double totalStrength = pullStrength3 + pullStrength2 + pullStrength1;
        double threshold =  (totalStrength / 3) * maxDistance;

        LXVector centerVector1 = model.blooms.get(35).center;
        // LXVector centerVector2 = model.blooms.get(bloom2).center;
        // LXVector centerVector3 = model.blooms.get(bloom3).center;

        double tempDist;

        for (LXPoint led : model.leds) {
            LXVector ledVector = LXPointToVector(led);
            tempDist = centerVector1.dist(ledVector);

            if (tempDist < threshold) {
                colors[led.index] = LXColor.hsb(360, 0, 100);
            }
            else {
                colors[led.index] = LXColor.hsb(0, 0, 0);

            }
        }
    }
}



// @LXCategory("Pulley")
// public class Aftershock extends RadiaLumiaPattern {
  
//     public final CompoundParameter pulley =
//         new CompoundParameter("pul", 0.5, 0, 1)
//         .setDescription("The pulley strength");

//     public final DiscreteParameter source =
//         new DiscreteParameter("src", 35, 0, 41);

//     public Aftershock(LX lx){
//         super(lx);
//         addParameter(this.pulley);
//         addParameter(this.source);
//     }

//     public void run(double deltaMs) {
//         double pullStrength = this.pulley.getValue();
//         int sourceBloom = this.source.getValuei();

//         int maxDistance = 500;
//         double threshold = pullStrength * maxDistance;

//         LXVector centerVector = model.blooms.get(sourceBloom).center;

//         double tempDist;

//         for (LXPoint led : model.leds) {
//             LXVector ledVector = LXPointToVector(led);
//             tempDist = centerVector.dist(ledVector);

//             if (tempDist < threshold) {
//                 colors[led.index] = LXColor.hsb(360, 0, 100);
//             }
//             else {
//                 colors[led.index] = LXColor.hsb(0, 0, 0);

//             }
//         }
//     }
// }