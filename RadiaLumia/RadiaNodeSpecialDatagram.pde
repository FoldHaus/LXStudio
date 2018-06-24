

public class RadiaNodeSpecialDatagram extends StreamingACNDatagram {

  /**
   * Constant universe that all pixlites are configured to forward to DMX512 auxillry output
   */
  protected final static int UNIVERSE = 24;
  
  // Until this gets exposed by StreamingACNDatagram
  private final static int DMX_DATA_POSITION = 126;

  protected final static int MOTOR_DATA_POSITION = 0;
  protected final static int MOTOR_DATA_LENGTH = 3;

  protected final static int PINSPOT_DATA_POSITION = MOTOR_DATA_POSITION + MOTOR_DATA_LENGTH;
  protected final static int PINSPOT_DATA_LENGTH = 2;

  protected final static int PAYLOAD_SIZE = PINSPOT_DATA_POSITION + PINSPOT_DATA_LENGTH;

  protected final static int CRC_SIZE = 1;

  protected final static int PACKET_SIZE = PAYLOAD_SIZE + CRC_SIZE;

  protected int motorPositionIndex;

  protected int pinspotIndex;

  public RadiaNodeSpecialDatagram(Bloom bloom) {
    super(UNIVERSE, PACKET_SIZE);
    motorPositionIndex = bloom.umbrella.position.index;

    pinspotIndex = bloom.spike.pinSpot.index;
  }

  @Override
  public void onSend(int[] colors) {
    // Use parent version of function to set sequence number
    super.onSend(colors);
    writeLENumberToBuffer(colors[motorPositionIndex], MOTOR_DATA_POSITION, MOTOR_DATA_LENGTH);
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
    // TODO: calculate CRC from stuff in `this.buffer`
    int crc = 0xAA;
    writeLENumberToBuffer(crc, PAYLOAD_SIZE, CRC_SIZE);
  }
}
