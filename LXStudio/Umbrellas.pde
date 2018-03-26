import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;
import com.jogamp.opengl.GL;
import com.jogamp.opengl.GL2;

public class UISimulation extends UI3dComponent {
  
  UIPlane ground;
  
  public UISimulation () {
    //addChild(ground = new UIPlane(250, 250, -35));
    addChild(umbrellaModel = new UIRadiaLumia());
  }
  
   protected void beginDraw(UI ui, PGraphics pg) {
    float level = 255;
    pg.pointLight(level, level, level, -50*FEET, 50*FEET, -50*FEET);
    pg.pointLight(level, level, level, 50*FEET, 50*FEET, -50*FEET);
    pg.pointLight(level, level, level, 0, 50 * FEET, 30*FEET);
  }
  
  protected void endDraw(UI ui, PGraphics pg) {
    pg.noLights();
  }
}

public class UIPlane extends UI3dComponent {
  float width;
  float height;
  float elevation;
  
  public UIPlane (float width, float height, float elevation) {
   this.width = width;
   this.height = height;
   this.elevation = elevation;
  }
  
  @Override
  public void onDraw(UI ui, PGraphics pg) {
    pg.fill(#A7784C);
    pg.textureMode(NORMAL);
    pg.beginShape();
    pg.vertex((-width/2) * FEET, elevation * FEET, (-height/2) * FEET);
    pg.vertex((-width/2) * FEET, elevation * FEET, (height/2) * FEET);
    pg.vertex((width/2) * FEET, elevation * FEET, (height/2) * FEET);
    pg.vertex((width/2) * FEET, elevation * FEET, (-height/2) * FEET);
    pg.endShape(CLOSE);
    
    pg.fill(#281403);
    pg.noStroke();
  }
}

public static class UIRadiaLumia extends UI3dComponent {
  
  public UIUmbrella[] umbrellas;
  
  public UIRadiaLumia () {
    umbrellas = new UIUmbrella[GeodesicModel3D.hubs.length - 1];
    for (int u = 0; u < umbrellas.length; u++){
      umbrellas[u] = new UIUmbrella(3 * FEET, .5 * FEET, 8 * FEET, 6, u, GeodesicModel3D.hubs[u]); 
    }
  }
  
  public void onDraw (UI ui, PGraphics pg) {
    
    for (UIUmbrella u : umbrellas) {
      pg.pushMatrix();
      
      final PVector directionA = new PVector(0, 1, 0).normalize();
      final PVector directionB = u.Position;
      directionB.normalize();
      
      float rotationAngle = (float)Math.acos(directionA.dot(directionB));
      final PVector rotationAxis = directionA.cross(directionB).normalize();
      
      pg.rotate (rotationAngle, rotationAxis.x, rotationAxis.y, rotationAxis.z);
      pg.translate (0, 1 * GeodesicModel3D.SCALE, 0);
      
      u.onDraw(ui, pg);
      
      pg.popMatrix();
    }
    
    
  }
}

public static class UIUmbrella extends UI3dComponent {
  
  public int BlossomIndex;
  public PVector Position;
  
  public float PercentClosed;
  
  // Closed
  private final PVector[] base;
  private final PVector[] top;
  
  // Open
  private final PVector[] base_open;
  private final PVector[] top_open;
  
  private final int detail;
  public final float len;
  
  public UIUmbrella(float radius, float len, int detail) {
    this(radius, radius, 0, len, detail);
  }
  
  public UIUmbrella(float baseRadius, float topRadius, float len, int detail) {
    this(baseRadius, topRadius, 0, len, detail);
  }
  
  public UIUmbrella(float baseRadius, float topRadius, float yMin, float yMax, int detail) {
    this.base = new PVector[detail];
    this.top = new PVector[detail];
    
    this.base_open = new PVector[detail];
    this.top_open = new PVector[detail];
    
    this.detail = detail;
    this.len = yMax - yMin;
    
    for (int i = 0; i < detail; ++i) {
      float angle = i * (TWO_PI / detail);
      this.base[i] = new PVector(baseRadius * cos(angle), yMin, baseRadius * sin(angle));
      this.base_open[i] = new PVector(baseRadius * 2.5 * cos(angle), yMin - (2 * FEET), baseRadius * 2.5 * sin(angle));
      
      this.top[i] = new PVector(topRadius * cos(angle), yMax, topRadius * sin(angle));
      this.top_open[i] = new PVector(topRadius * cos(angle), yMin + (1 * FEET), topRadius * sin(angle));
    }
  }
  
  public UIUmbrella(float baseRadius, float topRadius, float len, int detail, int blossomIndex, LXVector position) {
    this(baseRadius, topRadius, 0, len, detail);
    this.BlossomIndex = blossomIndex;
    this.Position = new PVector(position.x * GeodesicModel3D.SCALE, position.y * GeodesicModel3D.SCALE, position.z * GeodesicModel3D.SCALE);
    this.PercentClosed = 0;
  }
  
  public void onDraw(UI ui, PGraphics pg) {
    pg.fill(0x99FFFFFF);
    pg.stroke(#444444);
    pg.beginShape(TRIANGLE_STRIP);
    for (int i = 0; i <= this.detail; ++i) {
      int ii = i % this.detail;
      pg.vertex(lerp(this.base_open[ii].x, this.base[ii].x, PercentClosed), lerp(this.base_open[ii].y, this.base[ii].y, PercentClosed), lerp(this.base_open[ii].z, this.base[ii].z, PercentClosed));
      pg.vertex(lerp(this.top_open[ii].x, this.top[ii].x, PercentClosed), lerp(this.top_open[ii].y, this.top[ii].y, PercentClosed), lerp(this.top_open[ii].z, this.top[ii].z, PercentClosed));
    }
    pg.endShape(CLOSE);
  }
}
