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
        String[] DEBUG_MULTIPLE_IPS = {
            "192.168.1.240",
            "192.168.1.234",
            "192.168.1.218",
            "192.168.1.216",
            "192.168.1.215",
            "192.168.1.214",
            "192.168.1.213",
            "192.168.1.212",
            "192.168.1.209",
            "192.168.1.205",
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
            } else if (!BLOOM_DEBUG_ONE && BLOOM_DEBUG_THREE && (mappedBloomCount < DEBUG_MULTIPLE_IPS.length)) {
                if (stringIn(bloomConfig.getString("ip"), DEBUG_MULTIPLE_IPS)){
                    
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


int[] PENTA_BASE_SPOKE_ORDER = {0, 1, 2, 3, 4 };
int[] PENTA_MIRRORED_SPOKE_ORDER = { 4, 3, 2, 1, 0};

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
    
    int OrderedSpikeIndex = 0;
    int[] SpikeIndexOrder = PENTA_BASE_SPOKE_ORDER;
    if (bloom.MirrorOutputs)
    {
        SpikeIndexOrder = PENTA_MIRRORED_SPOKE_ORDER;
    }
    
    int[] CopyArray = new int[5];
    
    println();
    println("Remapping");
    println(SpikeIndexOrder);
    println();
    
    for (int i = 0; i < SpikeIndexOrder.length; i++)
    {
        int inValue = i;
        int outValue = (i + bloom.FlipValue) % SpikeIndexOrder.length;
        int valAtIndex = SpikeIndexOrder[outValue];
        
        println(" - " + inValue + " : " + outValue + " : " + valAtIndex);
        
        CopyArray[inValue] = SpikeIndexOrder[outValue];
    }
    
    SpikeIndexOrder = CopyArray;
    
    println();
    println(SpikeIndexOrder);
    println();
    
    try {
        // Mod 5 to ensure the value is always within 0-5 range
        
        println("Spoke " + OrderedSpikeIndex + " Rot Order: "  + SpikeIndexOrder[OrderedSpikeIndex] + ": " + universe);
        int[] indices = makeSpokeIndices(bloom, bloom.spokes.get(SpikeIndexOrder[OrderedSpikeIndex]), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpikeIndex++;
        
        // Spike
        println("Spike 1" + ": " + universe);
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 170, 0)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 170, 170)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 6, 340)).setAddress(ip));
        
        
        println("Spoke " + OrderedSpikeIndex + " Rot Order: "  + SpikeIndexOrder[OrderedSpikeIndex] + ": " + universe);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(SpikeIndexOrder[OrderedSpikeIndex]), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpikeIndex++;
        
        println("Spoke " + OrderedSpikeIndex + " Rot Order: "  + SpikeIndexOrder[OrderedSpikeIndex] + ": " +  universe);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(SpikeIndexOrder[OrderedSpikeIndex]), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpikeIndex++;
        
        println("Spoke " + OrderedSpikeIndex + " Rot Order: "  + SpikeIndexOrder[OrderedSpikeIndex] + ": " +  universe);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(SpikeIndexOrder[OrderedSpikeIndex]), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpikeIndex++;
        
        // Spike
        println("Spike 2" + ": " + universe);
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 170, 0)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 170, 170)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 6, 340)).setAddress(ip));
        
        
        println("Spoke " + OrderedSpikeIndex + " Rot Order: "  + SpikeIndexOrder[OrderedSpikeIndex] + ": " + universe);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(SpikeIndexOrder[OrderedSpikeIndex]), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpikeIndex++;
        
        // Set up DMX output
        output.addDatagram(new RadiaNodeSpecialDatagram(start_universe + DMX_UNIVERSE_OFFSET, bloom).setAddress(ip));
        
    } catch (Exception x) {
        println("Runtime Exception: " + x);
        throw new RuntimeException(x);
    }
}

int[] HEXA_BASE_SPOKE_ORDER = {0, 1, 2, 3, 4, 5};
int[] HEXA_FLIPPED_SPOKE_ORDER = {3, 4, 5, 0, 1, 2};
int[] HEXA_MIRRORED_SPOKE_ORDER = {0, 5, 4, 3, 2, 1};
int[] HEXA_FLIPPED_MIRRORED_SPOKE_ORDER = {3, 2, 1, 0, 5, 4};

void buildHexaBloomOutput (LX lx, LXDatagramOutput output, Config config, JSONObject bloomConfig, Bloom bloom, String ip)
{
    int start_universe = calculateStartUniverseFromIp(ip);
    int universe = start_universe;
    
    println("IP: " + ip + " Start Universe: " + start_universe + " DMX: " + (start_universe + DMX_UNIVERSE_OFFSET));
    
    int OrderedSpokeIndex = 0;
    int[] SpokeIndexOrder = HEXA_BASE_SPOKE_ORDER;
    if (bloom.FlipValue > 0)
    {
        if (bloom.MirrorOutputs)
        {
            println("MIRRORED + FLIPPED");
            SpokeIndexOrder = HEXA_FLIPPED_MIRRORED_SPOKE_ORDER;
        }
        else
        {
            println("FLIPPED");
            SpokeIndexOrder = HEXA_FLIPPED_SPOKE_ORDER;
        }
    }
    else
    {
        if (bloom.MirrorOutputs)
        {
            println("MIRRORED");
            SpokeIndexOrder = HEXA_MIRRORED_SPOKE_ORDER;
        }
        else
        {
            // Base Order
        }
    }
    
    try {
        
        // Short
        println("Short 0: " + SpokeIndexOrder[OrderedSpokeIndex]);
        int[] indices = makeSpokeIndices(bloom, bloom.spokes.get(SpokeIndexOrder[OrderedSpokeIndex]), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpokeIndex++;
        
        // Spike
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 170, 0)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 170, 170)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripA, 6, 340)).setAddress(ip));
        
        // Long 
        println("Long 0: " + SpokeIndexOrder[OrderedSpokeIndex]);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(SpokeIndexOrder[OrderedSpokeIndex]), universe, 123);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpokeIndex++;
        
        // Long
        println("Long 1: " + SpokeIndexOrder[OrderedSpokeIndex]);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(SpokeIndexOrder[OrderedSpokeIndex]), universe, 123);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpokeIndex++;
        
        // Short
        println("Short 1: " + SpokeIndexOrder[OrderedSpokeIndex]);
        println("SpokeIndex: " + SpokeIndexOrder[OrderedSpokeIndex] + " Universe: " + universe +" Before: " + OrderedSpokeIndex);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(SpokeIndexOrder[OrderedSpokeIndex]), universe, 102);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        
        OrderedSpokeIndex++;
        println("SpokeIndex: " + SpokeIndexOrder[OrderedSpokeIndex] + " Universe: " + universe + " After: " + OrderedSpokeIndex);
        
        // Spike
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripB, 170, 0)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripB, 170, 170)).setAddress(ip));
        output.addDatagram(new StreamingACNDatagram(universe++, makeIndices(bloom.spike.stripB, 6, 340)).setAddress(ip));
        
        // Long 
        println("Long 2: " + SpokeIndexOrder[OrderedSpokeIndex]);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(SpokeIndexOrder[OrderedSpokeIndex]), universe, 123);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpokeIndex++;
        
        // Long
        println("Long 3: " + SpokeIndexOrder[OrderedSpokeIndex]);
        indices = makeSpokeIndices(bloom, bloom.spokes.get(SpokeIndexOrder[OrderedSpokeIndex]), universe, 123);
        output.addDatagram(new StreamingACNDatagram(universe++, indices).setAddress(ip));
        OrderedSpokeIndex++;
        
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
