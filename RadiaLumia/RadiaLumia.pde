/** 
 * By using LX Studio, you agree to the terms of the LX Studio Software
 * License and Distribution Agreement, available at: http://lx.studio/license
 *
 * Please note that the LX license is not open-source. The license
 * allows for free, non-commercial use.
 *
 * HERON ARTS MAKES NO WARRANTY, EXPRESS, IMPLIED, STATUTORY, OR
 * OTHERWISE, AND SPECIFICALLY DISCLAIMS ANY WARRANTY OF
 * MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR A PARTICULAR
 * PURPOSE, WITH RESPECT TO THE SOFTWARE.
 */

// ---------------------------------------------------------------------------
//
// Welcome to LX Studio! Getting started is easy...
// 
// (1) Quickly scan this file
// (2) Look at "Model" to define your model
// (3) Move on to "Patterns" to write your animations
// 
// ---------------------------------------------------------------------------

// Reference to top-level LX instance
heronarts.lx.studio.LXStudio lx;

Config config;
Model model;
UIRadiaLumia umbrellaModel;

ProjectController ProjController;
UIProjectControllerPanel UIProjectControls;

Sensors sensors;
UISensors uiSensors;

ArtHausPerformance artHaus;

void setup() {
    // Processing setup, constructs the window and the LX instance
    size(800, 720, P3D);
    config = new Config();
    model = new Model(config);
    
    lx = new heronarts.lx.studio.LXStudio(this, model, MULTITHREADED);
    
    ProjController = new ProjectController(lx);
    
    UIProjectControls = (UIProjectControllerPanel)new UIProjectControllerPanel(
        lx.ui,
        lx.ui.leftPane.global.getContentWidth(),
        ProjController
        ).addToContainer((UIContainer)lx.ui.leftPane.global);
    lx.addProjectListener(UIProjectControls);
    
    sensors = new Sensors(lx);
    uiSensors = (UISensors)new UISensors(
        lx.ui,
        sensors,
        lx.ui.leftPane.global.getContentWidth()).addToContainer((UIContainer)lx.ui.leftPane.global);
    
    // Arthaus
    // TEMPORARY
    //artHaus = new ArtHausPerformance(lx);
    
    // Default, RadiaLumia specific effects
    ColorBalance cb = new ColorBalance(lx);
    lx.engine.masterChannel.addEffect(cb);
    cb.enabled.setValue(true);
    
    RadiaEntranceEffect ree = new RadiaEntranceEffect(lx);
    lx.engine.masterChannel.addEffect(ree);
    ree.enabled.setValue(true);
    
    RadiaWindProtect rwp = new RadiaWindProtect(lx);
    lx.engine.masterChannel.addEffect(rwp);
    rwp.enabled.setValue(true);
    
    lx.ui.setResizable(RESIZABLE);
}

void initialize(final heronarts.lx.studio.LXStudio lx, heronarts.lx.studio.LXStudio.UI ui) {
    buildOutput(lx);
    
    // Add a loop task to rate-limit and simulate umbrella position
    lx.engine.addLoopTask(new LXLoopTask() {
                          public void loop(double deltaMs) {
                          int[] colors = lx.getColors();
                          for (Bloom bloom : model.blooms) {
                          bloom.umbrella.update(deltaMs, colors);
                          }
                          }
                          });
    
    InitializeUmbrellaMask();
}

void onUIReady(heronarts.lx.studio.LXStudio lx, heronarts.lx.studio.LXStudio.UI ui) {
    // Add custom UI components here
    /* TODO(peter): model.leds doesn't and shouldn't include the pin spots. Create a
    new ArrayList called displayedInPointCloud, and use it here. Grrrr
    */
    ui.preview.pointCloud.setModel(new LXModel(model.displayPoints));
    ui.preview.addComponent(new UISimulation());
}

void draw() {
    // All is handled by LX Studio
    
}

// Configuration flags
final static boolean MULTITHREADED = true;
final static boolean RESIZABLE = true;

// Helpful global constants
final static float INCHES = 1;
final static float IN = INCHES;
final static float FEET = 12 * INCHES;
final static float FT = FEET;
final static float CM = IN / 2.54;
final static float MM = CM * .1;
final static float M = CM * 100;
final static float METER = M;

final static float PI = 3.1415;
final static float TWO_PI = PI * 2;

final static float UI_PADDING = 4;