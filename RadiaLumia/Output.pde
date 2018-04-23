// sACN E1.31 Protocol http://tsp.esta.org/tsp/documents/docs/E1-31-2016.pdf
// LXStudio API for StreamingACNDatagram http://lx.studio/api/heronarts/lx/output/StreamingACNDatagram.html#StreamingACNDatagram-int:A-
// Each E1.31 packet specifies a single universe = 512 channels = 170 LEDs
// Each PixLite 4 MkII supports 24 universe of pixel output over 8 physical output channels, up to 4080 LEDs
// Each hub will have between 1320 - 2328 LEDs || 8-14 universes || 8-14 Datagrams per frame per Hub

// Sample Setup
// 1 Output per Geodesic Edge = 5-6 Outputs, each with 2m LEDs = 288 LEDs
// Universes 1-12 = Geodesic Edges
// Universe 14-16 = Spike (2 Output, 300 LEDs each)
// Universe 24 = DMX Motor Control



void setupDatagrams() {
	datagrams.add((StreamingACNDatagram) new StreamingACNDatagram(lx, channels14, (byte) 0x00).setAddress(ip).setPort(OPC_PORT));
	// datagrams.add((StreamingACNDatagram) new StreamingACNDatagram(lx, channels14, (byte) 0x00).setAddress(ip).setPort(OPC_PORT));
}


// public static class RadialumiaDatagram extends StreamingACNDatagram {

//   static {
//     for (int b = 0; b < 256; ++b) {
//       for (int in = 0; in < 256; ++in) {
//         GAMMA_LUT[b][in] = (byte) (0xff & (int) Math.round(Math.pow(in * b / 65025.f, GAMMA) * 255.f));
//       }
//     }
//   }
    
//   private final LXParameter brightness; 
    
//   public RadialumiaDatagram(LX lx, int[] indices, byte universe) {
//     super(indices, channel);
//     this.brightness = lx.engine.output.brightness;
//   }
  
//   @Override
//   protected LXDatagram copyPoints(int[] colors, int[] pointIndices, int offset) {
//     final byte[] gamma = GAMMA_LUT[Math.round(255 * this.brightness.getValuef())];
//     int i = offset;
//     for (int index : pointIndices) {
//       int c = (index >= 0) ? colors[index] : #000000;
//       this.buffer[i    ] = gamma[0xff & (c >> 16)]; // R
//       this.buffer[i + 1] = gamma[0xff & (c >> 8)]; // G
//       this.buffer[i + 2] = gamma[0xff & c]; // B
//       i += 3;
//     }
//     return this;
//   }

// }