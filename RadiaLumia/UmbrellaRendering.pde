// UmbrellaRendering.pde
/*
  This file contains the code which handles rendering the drawing of the Umbrella
  simulation, based the Umbrella class in Model.pde
*/

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;
import com.jogamp.opengl.GL;
import com.jogamp.opengl.GL2;

public static float UMBRELLA_BOTH_OUTER_RADIUS = 10 * INCHES;

public static float UMBRELLA_OPEN_INNER_RADIUS = 45 * INCHES;
public static float UMBRELLA_OPEN_HEIGHT = 30 * INCHES;
public static float UMBRELLA_OPEN_OUTER_DISTANCE_FROM_CENTER = 18 * INCHES;
public static float UMBRELLA_OPEN_INNER_DISTANCE_FROM_CENTER = 12 * INCHES;

public static float UMBRELLA_CLOSED_INNER_RADIUS = 18 * INCHES;
public static float UMBRELLA_CLOSED_HEIGHT = 53 * INCHES;
public static float UMBRELLA_CLOSED_OUTER_DISTANCE_FROM_CENTER = 50 * INCHES;
public static float UMBRELLA_CLOSED_INNER_DISTANCE_FROM_CENTER = 3 * INCHES;

// Houses the actual simulated elements of the Preview interface
// at present, this is just the Umbrellas.
public class UISimulation extends UI3dComponent {
  
  public UISimulation () {
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

// Holds references to, and positions each of the Umbrellas around the structure.
public class UIRadiaLumia extends UI3dComponent {
  
  // @TODO(peter): separate data (to go somewhere else) from the rendering. All this class should do is render the same cylinder over and over again, at different positions and open/closed states
  public UIUmbrella hex_umbrella;
  public UIUmbrella pent_umbrella;
  
  public UIRadiaLumia () {
    hex_umbrella = new UIUmbrella (6);
	pent_umbrella = new UIUmbrella(5);
  }
  
  public void onDraw (UI ui, PGraphics pg) {
    
	  int numberDrawn = 0;
    for (Bloom b : model.blooms) {
		  numberDrawn += 1;
		  if (numberDrawn >= model.blooms.size()) {
			  continue;
      }

      pg.pushMatrix();
      
      // Find angle between "up" and 
      final PVector directionA = new PVector(0, 1, 0).normalize();
      final PVector directionB = new PVector(b.center.x, b.center.y, b.center.z);
      directionB.normalize();
      
      float rotationAngle = (float)Math.acos(directionA.dot(directionB));
      final PVector rotationAxis = directionA.cross(directionB).normalize();
      
      pg.rotate (rotationAngle, rotationAxis.x, rotationAxis.y, rotationAxis.z);

  	  // BEGIN TEMP CODE TO TRY AND ROTATE AROUND THE SPIKE AXIS
  	  /*
  	  float angleBetweenNeighborAndRight = GetRotationAroundSpikeAxis(pg, b);
  
     	  // rotate around up
  	  pg.popMatrix();
  	  pg.pushMatrix();
  
  	  pg.rotate (rotationAngle, rotationAxis.x, rotationAxis.y, rotationAxis.z);
  	  pg.rotate (angleBetweenNeighborAndRight, 0, 1, 0);
  	  */
  	  // END TEMP CODE

      pg.translate (0, 1 * Config.SCALE, 0);

	    int neighborCount = b.neighbors.size();
	  
  	  if (neighborCount == 5) {
  		  pent_umbrella.onDraw(ui, pg, (float)b.umbrella.GetPercentClosed());
  	  } else if (neighborCount == 6) {
  		  hex_umbrella.onDraw(ui, pg, (float)b.umbrella.GetPercentClosed());
  	  }

      pg.popMatrix();
	  }
  }

  public float GetRotationAroundSpikeAxis (PGraphics pg, Bloom b) {
   
	  pg.popMatrix();
	  pg.pushMatrix();
    // @TODO(peter): handle rotating umbrellas about their normal correctly

	  PMatrix curMatrix = pg.getMatrix();

	  // Apply current matrix to right
	  PVector right = new PVector(1, 0, 0);
	  PVector localRight = new PVector (0, 0, 0);
	  curMatrix.mult(right, localRight);

	  // angle between right and neighbor[0]
    Bloom neighborZero = b.neighbors.get(0);

	  PVector neighborZeroLocation = LXToPVector(neighborZero.center);
	  PVector bloomLocation = LXToPVector(b.center);

	  PVector bloomToNeighbor = neighborZeroLocation.sub(bloomLocation);
	  PVector bloomToNeighborProjOnBloomPlane = bloomToNeighbor.sub(bloomLocation.mult(bloomToNeighbor.dot(bloomLocation) / bloomLocation.magSq()));

	  float angleBetweenNeighborAndRight = bloomToNeighborProjOnBloomPlane.dot(localRight);

	  return angleBetweenNeighborAndRight;
  }
}

/* TESTING THIS CODE. IT DOESNT WORK YET 
public void testUmbrellaTransformCode () {

		PVector up = LXToPVector(b.center);

		int neighborZeroIndex = GeodesicModel3D.hub_graph[b.index][0];

		PVector neighborZeroLocation = LXToPVector(GeodesicModel3D.hubs[neighborZeroIndex]);
		PVector bloomLocation = LXToPVector(GeodesicModel3D.hubs[b.index]);

		PVector right = neighborZeroLocation.sub(bloomLocation).normalize();
		PVector forward = right.cross(up).normalize();
		
		PMatrix3D rotMatrix = new PMatrix3D(
			right.x, right.y, right.z, 0,
			forward.x, forward.y, forward.z, 0,
			up.x, up.y, up.z, 0, 
			0, 0, 0, 1
			);

		PMatrix3D rotMatrixB = new PMatrix3D(
			right.x, right.y, right.z, 0,
			up.x, up.y, up.z, 0,
			forward.x, forward.y, forward.z, 0,
			0, 0, 0, 1
			);

		pg.pushMatrix();
		pg.applyMatrix(rotMatrix);
		pg.translate (0, 1 * GeodesicModel3D.SCALE, 0);

		umbrella.onDraw(ui, pg, (float)b.umbrella.GetPercentClosed());
		
		pg.popMatrix();
		continue;

}
*/

public static class UIUmbrella {
  
  // Closed
  private final PVector[] closed_inner_spoke_positions;
  private final PVector[] closed_outer_spoke_positions;
  
  // Open
  private final PVector[] open_inner_spoke_positions;
  private final PVector[] open_outer_spoke_positions;
  
  private final int detail;
  public final float open_len;
  public final float closed_len;
		  
  public UIUmbrella(int detail) {
	  this.closed_inner_spoke_positions = new PVector[detail];
	  this.closed_outer_spoke_positions = new PVector[detail];

	  this.open_inner_spoke_positions = new PVector[detail];
	  this.open_outer_spoke_positions = new PVector[detail];
    
	  this.detail = detail;
	  this.open_len = UMBRELLA_OPEN_HEIGHT;
	  this.closed_len = UMBRELLA_CLOSED_HEIGHT;
	      
	  for (int i = 0; i < detail; ++i) {
		  float angle = i * (TWO_PI / detail);
		  
		  this.closed_inner_spoke_positions[i] = new PVector(UMBRELLA_CLOSED_INNER_RADIUS * cos(angle), -1 * UMBRELLA_CLOSED_INNER_DISTANCE_FROM_CENTER, UMBRELLA_CLOSED_INNER_RADIUS * sin(angle));
		  this.open_inner_spoke_positions[i] = new PVector(UMBRELLA_OPEN_INNER_RADIUS * cos(angle), -1 * UMBRELLA_OPEN_INNER_DISTANCE_FROM_CENTER, UMBRELLA_OPEN_INNER_RADIUS * sin(angle));
      
		  this.closed_outer_spoke_positions[i] = new PVector(UMBRELLA_BOTH_OUTER_RADIUS * cos(angle), UMBRELLA_CLOSED_OUTER_DISTANCE_FROM_CENTER, UMBRELLA_BOTH_OUTER_RADIUS * sin(angle));
		  this.open_outer_spoke_positions[i] = new PVector(UMBRELLA_BOTH_OUTER_RADIUS * cos(angle), UMBRELLA_OPEN_OUTER_DISTANCE_FROM_CENTER, UMBRELLA_BOTH_OUTER_RADIUS* sin(angle));
	  }
  }
  
  public void onDraw(UI ui, PGraphics pg, float PercentClosed) {
	  // Drawing Setup
	  pg.fill(0x99FFFFFF);
	  pg.stroke(#444444);
	  pg.beginShape(TRIANGLE_STRIP);

	  // 
	  for (int i = 0; i <= this.detail; ++i) {
		  int ii = i % this.detail;
		  pg.vertex(lerp(this.open_inner_spoke_positions[ii].x, this.closed_inner_spoke_positions[ii].x, PercentClosed), 
					lerp(this.open_inner_spoke_positions[ii].y, this.closed_inner_spoke_positions[ii].y, PercentClosed), 
					lerp(this.open_inner_spoke_positions[ii].z, this.closed_inner_spoke_positions[ii].z, PercentClosed));
		  pg.vertex(lerp(this.open_outer_spoke_positions[ii].x, this.closed_outer_spoke_positions[ii].x, PercentClosed), 
					lerp(this.open_outer_spoke_positions[ii].y, this.closed_outer_spoke_positions[ii].y, PercentClosed), 
					lerp(this.open_outer_spoke_positions[ii].z, this.closed_outer_spoke_positions[ii].z, PercentClosed));
	  }
	  pg.endShape(CLOSE);
  }
}
