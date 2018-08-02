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

int DMX_UNIVERSE_OFFSET = 24;


void buildOutput(LX lx) {
    try {
        LXDatagramOutput output = new LXDatagramOutput(lx);
        
        // Only debug first bloom output...
        boolean BLOOM_DEBUG_ONE = false;
        String DEBUG_ONE_IP = "192.168.1.215";
        
        // Debug three blooms, with the ips in the array
        boolean BLOOM_DEBUG_THREE = true;
        String[] DEBUG_THREE_IPS = {
            "192.168.1.216",
            "192.168.1.214",
            "192.168.1.200"
        };
        
        int mappedBloomCount = 0;
        
        for (Bloom bloom : model.blooms) {
            
            JSONObject bloomConfig = config.getBloom(bloom.id);
            String ip = bloomConfig.getString("ip");
            
            if (ip == null) {
                println("No IP address specified for Bloom #" + bloomConfig.getInt("id"));
            } else if (BLOOM_DEBUG_ONE && (mappedBloomCount < 1)) {
                
                if (bloom.spokes.size() == 6)
                {
                    buildHexaBloomOutput(lx, output, config, bloomConfig, bloom, DEBUG_ONE_IP);
                }else{
                    buildPentaBloomOutput(lx, output, config, bloomConfig, bloom, DEBUG_ONE_IP);
                }
                
                ++mappedBloomCount;
            } else if (!BLOOM_DEBUG_ONE && BLOOM_DEBUG_THREE && (mappedBloomCount < DEBUG_THREE_IPS.length)) {
                if (stringIn(bloomConfig.getString("ip"), DEBUG_THREE_IPS)){
                    
                    if (bloom.spokes.size() == 6)
                    {
                        buildHexaBloomOutput(lx, output, config, bloomConfig, bloom, bloomConfig.getString("ip"));
                    }
                    else
                    {
                        buildPentaBloomOutput(lx, output, config, bloomConfig, bloom, bloomConfig.getString("ip"));
                    }
                    
                    mappedBloomCount++;
                }
            }
        }
        
        lx.engine.addOutput(output);
        
    } catch (Exception x) {
        throw new RuntimeException(x);
    }
}

int calculateStartUniverseFromIp (String ip) {
    int UNIVERSES_PER_PIXLITE = 25;
    int INITIAL_IP_OFFSET = 200;
    String lastThree = ip.substring(ip.length() - 3);
    int id = int(lastThree) - INITIAL_IP_OFFSET; // Get the zero based index
    return (UNIVERSES_PER_PIXLITE * id); // Every pixlite takes up 24 universes
}

void buildPentaBloomOutput (LX lx, 
                            LXDatagramOutput output,
                            Config config,
                            JSONObject bloomConfig,
                            Bloom bloom, String ip)
{
    int start_universe = calculateStartUniverseFromIp(ip);
    int universe = start_universe;
    if(universe == 0)
        universe++;
    
    println("Start Universe: " + start_universe + " DMX: " + (start_universe + DMX_UNIVERSE_OFFSET));
    
    try {
        // Mod 5 to ensure the value is always within 0-5 range
        int spoke_index = bloom.FlipValue % 5;
        
        println("Spoke " + spoke_index + ": " + universe);
        int[] indices = makeSpokeIndices(bloom, bloom.spokes.get(spoke_index++), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        spoke_index = spoke_index % 5;
        
        // Spike
        println("Spike 1" + ": " + universe);
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 170, 0)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 170, 170)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 6, 340)).setAddress(ip));
        
        
        println("Spoke " + spoke_index + ": " + universe);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(spoke_index++), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        spoke_index = spoke_index % 5;
        
        println("Spoke " + spoke_index + ": " +  universe);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(spoke_index++), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        spoke_index = spoke_index % 5;
        
        println("Spoke " + spoke_index + ": " +  universe);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(spoke_index++), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        spoke_index = spoke_index % 5;
        
        // Spike
        println("Spike 2" + ": " + universe);
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 170, 0)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 170, 170)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 6, 340)).setAddress(ip));
        
        
        println("Spoke " + spoke_index + ": " + universe);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(spoke_index++), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        spoke_index = spoke_index % 5;
        
        // Set up DMX output
        output.addDatagram(new RadiaNodeSpecialDatagram(start_universe + DMX_UNIVERSE_OFFSET, bloom).setAddress(ip));
        
    } catch (Exception x) {
        println("Runtime Exception: " + x);
        throw new RuntimeException(x);
    }
}

void buildHexaBloomOutput (LX lx, LXDatagramOutput output, Config config, JSONObject bloomConfig, Bloom bloom, String ip)
{
    int start_universe = calculateStartUniverseFromIp(ip);
    int universe = start_universe;
    
    println("IP: " + ip + " Start Universe: " + start_universe + " DMX: " + (start_universe + DMX_UNIVERSE_OFFSET));
    
    try {
        
        // For hexa nodes, there are only two valid orientations, 
        //   1. rotated 0 degrees   (0 indecies)
        //   2. rotated 180 degrees (3 indecies)
        int startSpokeIndex = bloom.FlipValue > 0 ? 3 : 0;
        
        // Short
        println("Short 0: " + startSpokeIndex);
        int[] indices = makeSpokeIndices(bloom, bloom.spokes.get(startSpokeIndex), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        startSpokeIndex = (startSpokeIndex + 1) % 6;
        
        // Spike
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 170, 0)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 170, 170)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 6, 340)).setAddress(ip));
        
        // Long 
        println("Long 0: " + startSpokeIndex);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(startSpokeIndex), universe, 123);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        startSpokeIndex = (startSpokeIndex + 1) % 6;
        
        // Long
        println("Long 1: " + startSpokeIndex);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(startSpokeIndex), universe, 123);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        startSpokeIndex = (startSpokeIndex + 1) % 6;
        
        // Short
        println("Short 1: " + startSpokeIndex);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(startSpokeIndex), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        startSpokeIndex = (startSpokeIndex + 1) % 6;
        
        
        // Spike
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripB, 170, 0)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripB, 170, 170)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripB, 6, 340)).setAddress(ip));
        
        // Long 
        println("Long 2: " + startSpokeIndex);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(startSpokeIndex), universe, 123);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        startSpokeIndex = (startSpokeIndex + 1) % 6;
        
        // Long
        println("Long 3: " + startSpokeIndex);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(startSpokeIndex), universe, 123);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        startSpokeIndex = (startSpokeIndex + 1) % 6;
        
        // Set up DMX output
        output.addDatagram(new RadiaNodeSpecialDatagram(start_universe + DMX_UNIVERSE_OFFSET, bloom).setAddress(ip));
        
    } catch (Exception x) {
        println("Runtime Exception: " + x);
        throw new RuntimeException(x);
    }
    
}

Bloom.Spoke getCorrespondingNeighborSpoke(Bloom.Spoke _spoke, int bloomIndex) {
    Bloom neighborBloom = model.blooms.get(_spoke.pointsAtBloomIndex);
    for (Bloom.Spoke n_spoke : neighborBloom.spokes) {
        if (n_spoke.pointsAtBloomIndex == bloomIndex)
            return n_spoke;
    }
    return null;
}

int[] makeSpokeIndices(Bloom _bloom, Bloom.Spoke _spoke, int _startUniverse, int num) {
    int[] indices = new int[num];
    int curr_index = 0;
    
    Bloom.Spoke neighborSpoke = getCorrespondingNeighborSpoke(_spoke, _bloom.id);
    
    for (int src = 0; src < _spoke.outPoints.size(); src++) {
        indices[curr_index] = _spoke.outPoints.get(src).index;
        curr_index++;
    }
    
    for (int src = neighborSpoke.inPoints.size() - 1; src >= 0; src--) {
        indices[curr_index] = neighborSpoke.inPoints.get(src).index;
        curr_index++;
    }
    
    return indices;
}

int[] makeIndices(LXFixture fixture, int num, int offset) {
    List<LXPoint> points = fixture.getPoints();
    return makeIndices(points, num, offset);
}

int[] makeIndices(List<LXPoint> leds, int num, int offset) {
    int[] indices = new int[num];
    for (int i = 0; i < indices.length; ++i) {
        indices[i] = leds.get(offset + (i % leds.size())).index;
    }
    return indices;
}
