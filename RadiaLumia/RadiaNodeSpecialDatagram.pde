

public class RadiaNodeSpecialDatagram extends StreamingACNDatagram {
    // Until this gets exposed by StreamingACNDatagram
    private final static int DMX_DATA_POSITION = 126;
    private final static int SEQUENCE_NUMBER_POSITION = 111;
    private byte sequenceNumber = 0;
    
    protected final static int MOTOR_DATA_POSITION = 0;
    protected final static int MOTOR_DATA_LENGTH = 3;
    public final static int MOTOR_DATA_MASK = (1 << (MOTOR_DATA_LENGTH * 8)) - 1;
    
    protected final static int PINSPOT_DATA_POSITION = MOTOR_DATA_POSITION + MOTOR_DATA_LENGTH;
    protected final static int PINSPOT_DATA_LENGTH = 1;
    
    protected final static int PAYLOAD_SIZE = PINSPOT_DATA_POSITION + PINSPOT_DATA_LENGTH;
    
    protected final static int CRC_SIZE = 1;
    
    protected final static int PACKET_SIZE = PAYLOAD_SIZE + CRC_SIZE;
    
    protected int motorPositionIndex;
    
    protected int pinspotIndex;
    
    // Special Messages
    public boolean SendDoHomingMessage = false;
    public boolean SendInitHexa = false;
    public boolean SendInitPenta = false;
    
    public RadiaNodeSpecialDatagram(int universe, Bloom bloom) {
        super(universe, PACKET_SIZE);
        motorPositionIndex = bloom.umbrella.position.index;
        
        pinspotIndex = bloom.spike.pinSpot.index;
    }
    
    @Override
        public void onSend(int[] colors) {
        if (SendDoHomingMessage)
        {
            SendDoHomingMessage = false;
            // TODO(cameron): Write Homing Message
        }
        else if (SendInitHexa)
        {
            SendInitHexa = false;
            // TODO(cameron): Write Init Hexa Message
        }
        else if (SendInitPenta)
        {
            SendInitPenta = false;
            // TODO(cameron): Write Init Penta Message
        }
        else
        {
            // Do this manually for now since `super.onSend(colors)` doesn't work for some reason
            this.buffer[SEQUENCE_NUMBER_POSITION] = ++this.sequenceNumber;
            
            writeLENumberToBuffer(colors[motorPositionIndex], MOTOR_DATA_POSITION, MOTOR_DATA_LENGTH);
            writeLENumberToBuffer(colors[pinspotIndex], PINSPOT_DATA_POSITION, PINSPOT_DATA_LENGTH);
            writePayloadCRC();
        }
    }
    
    protected void writeLENumberToBuffer(int number, int pos, int length) {
        while (length-- != 0) {
            this.buffer[DMX_DATA_POSITION + pos++] = (byte)(number & 0xff);
            number >>= 8;
        }
    }
    
    protected void writePayloadCRC() {
        // TODO: calculate CRC from stuff in `this.buffer`
        int crc = 0xAA;
        writeLENumberToBuffer(crc, PAYLOAD_SIZE, CRC_SIZE);
    }
    
    public void doHome() {
        println("Do Home");
        SendDoHomingMessage = true;
    }
    
    public void setHex() {
        println("setting to Hex node");
        SendInitHexa = true;
    }
    
    public void setPenta() {
        println("setting to Penta node");
        SendInitPenta = true;
    }
}
