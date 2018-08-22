

public class RadiaNodeSpecialDatagram extends StreamingACNDatagram {
    // Until this gets exposed by StreamingACNDatagram
    private final static int DMX_DATA_POSITION = 126;
    private final static int SEQUENCE_NUMBER_POSITION = 111;
    private byte sequenceNumber = 0;
    
    protected final static int MARKER = 0xAA;
    protected final static int MARKER_POSITION = 0;
    protected final static int MARKER_LENGTH = 1;

    protected final static int COMMAND_POSITION = MARKER_POSITION + MARKER_LENGTH;
    protected final static int COMMAND_LENGTH = 1;
    
    protected final static int MOTOR_DATA_POSITION = COMMAND_POSITION + COMMAND_LENGTH;
    protected final static int MOTOR_DATA_LENGTH = 2;
    public final static int MOTOR_DATA_MASK = (1 << (MOTOR_DATA_LENGTH * 8)) - 1;
    
    protected final static int PINSPOT_DATA_POSITION = MOTOR_DATA_POSITION + MOTOR_DATA_LENGTH;
    protected final static int PINSPOT_DATA_LENGTH = 1;
    
    protected final static int PAYLOAD_SIZE = MARKER_LENGTH + COMMAND_LENGTH + MOTOR_DATA_LENGTH + PINSPOT_DATA_LENGTH;
    
    protected final static int CRC_POSITION = MARKER_POSITION + PAYLOAD_SIZE;
    protected final static int CRC_SIZE = 1;
    
    protected final static int PACKET_SIZE = PAYLOAD_SIZE + CRC_SIZE;
    
    protected int motorPositionIndex;
    
    protected int pinspotIndex;
    
    public int BloomId;

    protected CRC8 crc = new CRC8(0);
    
    // Special Messages
    public boolean SendDoHomingMessage = false;
    public boolean SendMaxPulses = false;
    
    public RadiaNodeSpecialDatagram(int universe, Bloom bloom) {
        super(universe, PACKET_SIZE);
        motorPositionIndex = bloom.umbrella.position.index;
        
        pinspotIndex = bloom.spike.pinSpot.index;
        BloomId = bloom.id;

        writeLENumberToBuffer(MARKER, MARKER_POSITION, MARKER_LENGTH);
    }
    
    @Override
        public void onSend(int[] colors) {
        if (SendDoHomingMessage)
        {
            SendDoHomingMessage = false;
            
            writeLENumberToBuffer(0xff, COMMAND_POSITION, COMMAND_LENGTH);
        }
        else if (SendMaxPulses)
        {
            SendMaxPulses= false;
            
            Bloom.Umbrella CurrentUmbrella = model.blooms.get(BloomId).umbrella;
            
            writeLENumberToBuffer(1, COMMAND_POSITION, COMMAND_LENGTH);
            writeLENumberToBuffer(CurrentUmbrella.MaxPulses, MOTOR_DATA_POSITION, MOTOR_DATA_LENGTH);
        }
        else
        {
            writeLENumberToBuffer(0, COMMAND_POSITION, COMMAND_LENGTH);
            writeLENumberToBuffer(colors[motorPositionIndex], MOTOR_DATA_POSITION, MOTOR_DATA_LENGTH);
        }
        
        // Do this manually for now since `super.onSend(colors)` doesn't work for some reason
        this.buffer[SEQUENCE_NUMBER_POSITION] = ++this.sequenceNumber;
        
        writeLENumberToBuffer(colors[pinspotIndex], PINSPOT_DATA_POSITION, PINSPOT_DATA_LENGTH);
        
        writePayloadCRC();
    }
    
    protected void writeLENumberToBuffer(int number, int pos, int length) {
        while (length-- != 0) {
            this.buffer[DMX_DATA_POSITION + pos++] = (byte)(number & 0xff);
            number >>= 8;
        }
    }
    
    protected void writePayloadCRC() {
        crc.reset();
        crc.update(this.buffer, DMX_DATA_POSITION, PAYLOAD_SIZE);
        writeLENumberToBuffer((int)crc.getValue(), CRC_POSITION, CRC_SIZE);
    }
    
    public void doHome() {
        println("Do Home");
        SendDoHomingMessage = true;
    }
    
    public void setSendMaxPulses()
    {
        println("Sending Pulses");
        SendMaxPulses = true;
    }
}
