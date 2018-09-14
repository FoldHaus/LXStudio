

@LXCategory("Pulley")
  public class HoldAndFire extends RadiaLumiaPattern {

  private final static int maxSensorPull = 20;
  private final static int minPull = 2;

  public final CompoundParameter pul1 =
    new CompoundParameter("pul1", 0, 0, maxSensorPull)
    .setDescription("The pulley strength");


  public final CompoundParameter pul2 =
    new CompoundParameter("pul2", 0, 0, maxSensorPull)
    .setDescription("The pulley strength");


  public final CompoundParameter pul3 =
    new CompoundParameter("pul3", 0, 0, maxSensorPull)
    .setDescription("The pulley strength");


  public final BooleanParameter liveSensor =
    new BooleanParameter("live", false)
    .setDescription("Use sensor cache fromm OSC");
    
  public final BooleanParameter debug =
    new BooleanParameter("dbg", false);


  public final CompoundParameter speed = 
    new CompoundParameter("spe", 1000, 0, 5000)
    .setDescription("Current offset of the sin wave");

  public final CompoundParameter p_offset =
    new CompoundParameter("off", 75, 0, 300);

  public final CompoundParameter p_scale =
    new CompoundParameter("scale", 75, 0, 300);


  public final CompoundParameter p_oscillatorMax =
    new CompoundParameter("max", 75, 0, 300);

  public final SawLFO oscillator =
    new SawLFO(0, p_oscillatorMax, speed);


  public CompoundParameter SensorRef_PullState1;
  public CompoundParameter SensorRef_PullState2;
  public CompoundParameter SensorRef_PullState3;

  private pulley pulley1, pulley2, pulley3;

  private final static int avgSize = 50;
  private final static int maxDistance = 95;
  private int bloomId1 = 1;
  private final static int bloomId2 = 4;
  private final static int bloomId3 = 11;

  private MovingAverage pullAvg1, pullAvg2, pullAvg3;


  private final static double ledRate = 0.25;

  public HoldAndFire(LX lx) {
    super(lx);
    addParameter(this.pul1);
    addParameter(this.pul2);
    addParameter(this.pul3);
    addParameter(this.liveSensor);
    addParameter(this.speed);

    // Debug
    addParameter(this.debug);
    addParameter(this.p_scale);
    addParameter(this.p_offset);
    addParameter(this.p_oscillatorMax);

    pullAvg1 = new MovingAverage(avgSize);
    pullAvg2 = new MovingAverage(avgSize);
    pullAvg3 = new MovingAverage(avgSize);

    pulley1 = new pulley(bloomId1);
    pulley2 = new pulley(bloomId2);
    pulley3 = new pulley(bloomId3);

    SensorRef_PullState1 = sensors.SensorValueCache.get(Sensors.SENSOR_ADDRESS_PULLEY_ONE);
    SensorRef_PullState2 = sensors.SensorValueCache.get(Sensors.SENSOR_ADDRESS_PULLEY_TWO);
    SensorRef_PullState3 = sensors.SensorValueCache.get(Sensors.SENSOR_ADDRESS_PULLEY_THREE);

    startModulator(this.oscillator);
  }

  public void run(double deltaMs) {

    boolean live = this.liveSensor.getValueb();

    if (live) {
      
      //pulley1.currForce = pullAvg1.NextVal(this.SensorRef_PullState1.getValue());
      //pulley2.currForce = pullAvg2.NextVal(this.SensorRef_PullState2.getValue());
      //pulley3.currForce = pullAvg3.NextVal(this.SensorRef_PullState3.getValue());
      
      
      if (this.debug.getValueb())
      {
        // TODO(peter): these aren't parameters, we aren't sure why they dont work
        pulley1.currForce = this.SensorRef_PullState1.getValue();
        pulley2.currForce = this.SensorRef_PullState2.getValue();
        pulley3.currForce = this.SensorRef_PullState3.getValue();
      }
      else
      {
        pulley1.currForce = pullAvg1.NextVal(sensors.SensorValueCache.get(Sensors.SENSOR_ADDRESS_PULLEY_ONE).getValue());
        pulley2.currForce = pullAvg2.NextVal(sensors.SensorValueCache.get(Sensors.SENSOR_ADDRESS_PULLEY_TWO).getValue());
        pulley3.currForce = pullAvg3.NextVal(sensors.SensorValueCache.get(Sensors.SENSOR_ADDRESS_PULLEY_THREE).getValue());
      }
      /*
      if (pulley1.currForce >= .5 || pulley2.currForce >= .5 || pulley3.currForce >= .5) {
        println(pulley1.currForce + " " + pulley2.currForce + " " + pulley3.currForce);
      }*/
    } else {
      pulley1.currForce = pullAvg1.NextVal(this.pul1.getValue());
      pulley2.currForce = pullAvg2.NextVal(this.pul2.getValue());
      pulley3.currForce = pullAvg3.NextVal(this.pul3.getValue());
    }



    // check if the pulley is being held
    if (pulley1.currForce > minPull) {
      pulley1.isHeld = true;
    } else {
      pulley1.isHeld = false;
    }

    if (pulley2.currForce > minPull) {
      pulley2.isHeld = true;
    } else {
      pulley2.isHeld = false;
    }

    if (pulley3.currForce > minPull) {
      pulley3.isHeld = true;
    } else {
      pulley3.isHeld = false;
    }


    if (pulley1.isHeld) {
      updateHold(pulley1);
    }

    if (pulley2.isHeld) {
      updateHold(pulley2);
    }
    if (pulley3.isHeld) {
      updateHold(pulley3);
    } 
    
    if ((!pulley3.isHeld && (pulley3.numHeldLed > 0)) || (!pulley2.isHeld && (pulley2.numHeldLed > 0)) || (!pulley1.isHeld && (pulley1.numHeldLed > 0))) {
      updateFire();
    }
    
    if ( (pulley3.numHeldLed <= 0) && (pulley2.numHeldLed <= 0) && (pulley1.numHeldLed <= 0) ) {
      for (Bloom bloom: model.blooms) {
        if ((bloom.id != bloomId1) && (bloom.id != bloomId2) && (bloom.id != bloomId3)) {
          for (LXPoint led: bloom.leds) {
             colors[led.index] = LXColor.hsb(0,0,0);
          }
        }
      }
    
    }
    
    if (pulley1.numHeldLed <= 0) {
      pulley1.loadedHeldLed = 0;
    }
    
    if (pulley2.numHeldLed <= 0) {
      pulley2.loadedHeldLed = 0;
    }
    
    if (pulley3.numHeldLed <= 0) {
      pulley3.loadedHeldLed = 0;
    }
  }

  public void updateHold(pulley p) {
    Bloom b = model.blooms.get(p.bloomId);

    double fracStrength = p.currForce / maxSensorPull;
    double ledNumChange = fracStrength * ledRate;

    if (p.numHeldLed >= maxDistance) {
      p.reachedMax = true;
    } else {
      p.reachedMax = false;
    }

    if (p.reachedMax == false) {
      p.numHeldLed += ledNumChange;

      LXVector ledVector;
      double dist;

      LXVector pCenter = b.center;
      for (LXPoint led : model.leds) {
        ledVector = LXPointToVector(led);

        int prevColor = colors[led.index];
        int blendColor = LXColor.hsb(360, 0, 100);

        dist = pCenter.dist(ledVector);

        if (dist < p.numHeldLed) {        
          colors[led.index] = LXColor.blend(prevColor, blendColor, LXColor.Blend.ADD);
        }
      }
    }
  }
  
  public void updateFire() {
    Bloom b1 = model.blooms.get(pulley1.bloomId);
    Bloom b2 = model.blooms.get(pulley2.bloomId);
    Bloom b3 = model.blooms.get(pulley3.bloomId);
    
    Boolean isFiring1 = false;
    Boolean isFiring2 = false;
    Boolean isFiring3 = false;
    
    LXVector ledVector;

    float dist;
    
    
    if (pulley1.numHeldLed > 0) {
      isFiring1 = true;
    }
    
    if (pulley2.numHeldLed > 0) {
      isFiring2 = true;
    }
    
    if (pulley3.numHeldLed > 0) {
      isFiring3 = true;
    }
    
    
    
    
    float off = this.oscillator.getValuef();
  

    float offset = p_offset.getValuef();
    float scale = p_scale.getValuef();

    for (LXPoint led : model.leds) 
    {
      ledVector = LXPointToVector(led);

      float distToCenterOne = b1.center.dist(ledVector);
      float distToCenterTwo = b2.center.dist(ledVector);
      float distToCenterThree = b3.center.dist(ledVector);
      

      dist = min(distToCenterOne, min(distToCenterTwo, distToCenterThree));


      float distToWave = abs(dist - (off)) % offset;
      if (distToWave > scale)
      {
        distToWave = 0f;
      } else
      {
        // In wave
      }


      distToWave /= scale;
      distToWave = 1f - distToWave;
      distToWave = constrain(1 - (distToWave * 4), 0, 1);

      float brightness = 100 * distToWave;
      
      
      if (dist > maxDistance) {
         if (isFiring1 || isFiring2 || isFiring3) {
           colors[led.index] = LXColor.hsb(360, 0, brightness);
         }
      }
    }
    
    
    
    if (pulley1.numHeldLed > 0) {
        if (pulley1.loadedHeldLed == 0) {
          pulley1.loadedHeldLed = pulley1.numHeldLed;
        }
        pulley1.reachedMax = false;
        pulley1.numHeldLed -= ledRate;

        for (LXPoint led: model.leds) {
            ledVector = LXPointToVector(led);

            int prevColor = colors[led.index];
            int blendColor = LXColor.hsb(360, 0, 100);

            dist = b1.center.dist(ledVector);

            //if (dist <= (maxDistance - pulley1.numHeldLed) && dist <= maxDistance) {
            if (dist <= pulley1.loadedHeldLed - pulley1.numHeldLed) {
                colors[led.index] = LXColor.blend(prevColor, blendColor, LXColor.Blend.SUBTRACT);
            }
        }
    }
    
    if (pulley2.numHeldLed > 0) {
        if (pulley2.loadedHeldLed == 0) {
          pulley2.loadedHeldLed = pulley2.numHeldLed;
        }
        pulley2.reachedMax = false;
        pulley2.numHeldLed -= ledRate;

        for (LXPoint led: model.leds) {
            ledVector = LXPointToVector(led);

            int prevColor = colors[led.index];
            int blendColor = LXColor.hsb(360, 0, 100);

            dist = b2.center.dist(ledVector);

            //if (dist <= (maxDistance - pulley2.numHeldLed) && dist <= maxDistance) {
              if (dist <= pulley2.loadedHeldLed - pulley2.numHeldLed) {
                colors[led.index] = LXColor.blend(prevColor, blendColor, LXColor.Blend.SUBTRACT);
            }
        }
    }
    
    
    if (pulley3.numHeldLed > 0) {
        if (pulley3.loadedHeldLed == 0) {
          pulley3.loadedHeldLed = pulley3.numHeldLed;
        }
        pulley3.reachedMax = false;
        pulley3.numHeldLed -= ledRate;

        for (LXPoint led: model.leds) {
            ledVector = LXPointToVector(led);

            int prevColor = colors[led.index];
            int blendColor = LXColor.hsb(360, 0, 100);

            dist = b3.center.dist(ledVector);

            //if (dist <= (maxDistance - pulley3.numHeldLed) && dist <= maxDistance) {        
              if (dist <= pulley3.loadedHeldLed - pulley3.numHeldLed) {
                colors[led.index] = colors[led.index] = LXColor.blend(prevColor, blendColor, LXColor.Blend.SUBTRACT);
            }
        }
    }    
  }
}




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
    new BooleanParameter("live", false)
    .setDescription("Use sensor cache fromm OSC");


  public CompoundParameter SensorRef_PullState1;
  public CompoundParameter SensorRef_PullState2;
  public CompoundParameter SensorRef_PullState3;

  private pulley pulley1, pulley2, pulley3;

  private final static int avgSize = 50;
  private final static int maxDistance = 500;
  private int bloomId1 = 35;
  private final static int bloomId2 = 22;
  private final static int bloomId3 = 36;

  private MovingAverage pullAvg1, pullAvg2, pullAvg3;

  public LoadingWipe(LX lx) {
    super(lx);
    addParameter(this.pul1);
    addParameter(this.pul2);
    addParameter(this.pul3);
    addParameter(this.liveSensor);

    pullAvg1 = new MovingAverage(avgSize);
    pullAvg2 = new MovingAverage(avgSize);
    pullAvg3 = new MovingAverage(avgSize);

    pulley1 = new pulley(bloomId1);
    pulley2 = new pulley(bloomId2);
    pulley3 = new pulley(bloomId3);

    SensorRef_PullState1 = sensors.SensorValueCache.get(Sensors.SENSOR_ADDRESS_PULLEY_ONE);
    SensorRef_PullState2 = sensors.SensorValueCache.get(Sensors.SENSOR_ADDRESS_PULLEY_TWO);
    SensorRef_PullState3 = sensors.SensorValueCache.get(Sensors.SENSOR_ADDRESS_PULLEY_THREE);
  }


  public void run(double deltaMs) {

    boolean live = liveSensor.getValueb();
    println(live);

    // double curr, prev1, prev2, prev3 = 0.0;

    if (live) {
      // curr = this.SensorRef_PullState1.getValue();
      // if (curr != prev1) {
      //     pullStrength1 = pullAvg1.NextVal(curr); 
      //     prev1 = curr;
      // }

      pulley1.currForce = pullAvg1.NextVal(this.SensorRef_PullState1.getValue());
      pulley2.currForce = pullAvg2.NextVal(this.SensorRef_PullState2.getValue());
      pulley3.currForce = pullAvg3.NextVal(this.SensorRef_PullState3.getValue());
    } else {
      pulley1.currForce = pullAvg1.NextVal(this.pul1.getValue());
      pulley2.currForce = pullAvg2.NextVal(this.pul2.getValue());
      pulley3.currForce = pullAvg3.NextVal(this.pul3.getValue());
    }


    // double totalStrength = pullStrength3 + pullStrength2 + pullStrength1;

    updateColors(pulley1, LXColor.BLUE);
    updateColors(pulley2, LXColor.GREEN);
    updateColors(pulley3, LXColor.RED);
  }

  public void updateColors(pulley p, int c) {
    int prevColor, blendColor, newColor;
    LXVector ledVector;
    double dist;

    LXVector pCenter = model.blooms.get(p.bloomId).center;
    for (LXPoint led : model.leds) {
      ledVector = LXPointToVector(led);

      dist = pCenter.dist(ledVector);
      prevColor = colors[led.index];
      blendColor = c;

      if (dist < p.currForce * maxDistance) {                
        newColor = LXColor.blend(prevColor, blendColor, LXColor.Blend.ADD);
      } else {
        newColor = LXColor.blend(prevColor, blendColor, LXColor.Blend.SUBTRACT);
      }

      colors[led.index] = newColor;
    }
  }
}


public class pulley {
  public double currForce;
  public int bloomId;
  public boolean isHeld;

  public boolean reachedMax;
  public double loadedHeldLed;
  public double numHeldLed;

  public List<pulleyEvent> pulleyHistory; //TODO: this might be a file output stream for performance reason


  // what's stored at pulley event
  class pulleyEvent {
    public double force;
    public String time; // TODO: convert to java date format object

    public pulleyEvent(double force, String time) {
      this.force = force;
      this.time = time;
    }
  }

  // constructor
  public pulley(int bloomId) {
    this.currForce = 0.0;
    this.bloomId = bloomId;
    this.pulleyHistory = new ArrayList<pulleyEvent>();
    this.isHeld = false;
    this.loadedHeldLed = 0.0;;
    this.reachedMax = false;
    this.numHeldLed = 0.0;
  }

  // add event
  public void addEvent(double force, String time) {
    pulleyEvent p = new pulleyEvent(force, time);
    pulleyHistory.add(p);
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
