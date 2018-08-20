public static class Sensors implements LXOscListener {
    
    public static final int OSC_PORT = 7878;
    
    public static final String SENSOR_ADDRESS_ROOT = "/sensor";
    
    public static final String SENSOR_ADDRESS_LADDER = SENSOR_ADDRESS_ROOT + "/ladder/weighted";
    public static final String SENSOR_ADDRESS_ANEMOMETER =
        SENSOR_ADDRESS_ROOT + "/wind";
    public static final String SENSOR_ADDRESS_PULLEY_ROOT = SENSOR_ADDRESS_ROOT + "/mshell";
    
    public static final String SENSOR_ADDRESS_PULLEY_ONE = SENSOR_ADDRESS_PULLEY_ROOT + "/1/pull";
    public static final String SENSOR_ADDRESS_PULLEY_TWO = SENSOR_ADDRESS_PULLEY_ROOT + "/2/pull";
    public static final String SENSOR_ADDRESS_PULLEY_THREE = SENSOR_ADDRESS_PULLEY_ROOT + "/3/pull";
    
    // Cached Values
    public HashMap<String, CompoundParameter> SensorValueCache;
    
    public Boolean DebugOSC;
    
    public Sensors()
    {
        // println("[Sensors] | Constructor");
        this.DebugOSC = true;
        
        SensorValueCache = new HashMap<String, CompoundParameter>();
        SensorValueCache.put(
            SENSOR_ADDRESS_LADDER, 
            new CompoundParameter(
            "ladder",
            0,0,1
            ).setDescription("The value received from the ladder load cells")
            );
        SensorValueCache.put(
            SENSOR_ADDRESS_ANEMOMETER,
            new CompoundParameter(
            "anemometer",
            0, 0, 1
            ).setDescription("The value received from the wind anemometer")
            );
        SensorValueCache.put(
            SENSOR_ADDRESS_PULLEY_ONE, 
            new CompoundParameter(
            "pulley1",
            0, 0, 1
            ).setDescription("The value received from the 1st  umbrella pulley"));
        SensorValueCache.put(
            SENSOR_ADDRESS_PULLEY_TWO,
            new CompoundParameter(
            "pulley2",
            0, 0, 1
            ).setDescription("The value received from the 2nd umbrella pulley")
            );
        SensorValueCache.put(
            SENSOR_ADDRESS_PULLEY_THREE,
            new CompoundParameter(
            "pulley2",
            0, 0, 1
            ).setDescription("The value received from the 3rd umbrella pulley")
            );
    }

    public void config (LX lx) {
        try {
            lx.engine.osc.receiver(OSC_PORT).addListener(this);
        }
        catch (java.net.SocketException sx)
        {
            throw new RuntimeException(sx);
        }
    }
    
    public void oscMessage (OscMessage message)
    {
        String Path = message.getAddressPattern().getValue();
        double Value = (double)message.getFloat(0);
        
        CompoundParameter Para = (CompoundParameter)SensorValueCache.get(Path);
        Para.setValue(Value);
        
        DebugSensorMessages(Path, Value, Para);
    }
    
    public void DebugSensorMessages(
        String _Path, 
        double _Value,
        CompoundParameter _Para
        )
    {
        if (this.DebugOSC)
        {
            println("OSC Message Received");
            println("Path: " + _Path);
            println("Value: " + _Value);
            println("Parameter Value: " + _Para.getValue());
            println("");
        }
    }
}

public class UISensors extends UICollapsibleSection
{
    public UISensors(
        UI _UI,
        Sensors _Sensors,
        float _W
        )
    {
        super(_UI, 0, 0, _W, 0);
        setTitle("SENSORS");
        
        setLayout(UI2dContainer.Layout.VERTICAL);
        setChildMargin(2, 0);
        
        // TODO(peter): display cached values from sensors here
    }
}