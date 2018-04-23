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


void buildOutput(LX lx) {
  try {
    LXDatagramOutput output = new LXDatagramOutput(lx);
    
    for (Bloom bloom : model.blooms) {
      JSONObject bloomConfig = config.getBloom(bloom.index);
      String ip = bloomConfig.getString("ip");
      if (ip != null) {
        int universe = 0;
        for (Bloom.Spoke spoke : bloom.spokes) {
          // TODO: handle splitting if these are more than 1-universe worth of pixels
          output.addDatagram(new StreamingACNDatagram(universe, LXFixture.Utils.getIndices(bloom.spike)).setAddress(ip));
          universe += 2;
        }
        output.addDatagram(new StreamingACNDatagram(13, LXFixture.Utils.getIndices(bloom.spike)).setAddress(ip));
        
        // TODO: add DMX umbrella control outputs
      }
    }
    
    lx.engine.addOutput(output);
  } catch (Exception x) {
    throw new RuntimeException(x);
  }
}
