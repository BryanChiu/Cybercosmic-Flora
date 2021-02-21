import com.thomasdiewald.liquidfun.java.DwWorld;
import com.thomasdiewald.liquidfun.java.DwParticleEmitter;
import com.thomasdiewald.liquidfun.java.interaction.DwParticleDestroyer;
import com.thomasdiewald.liquidfun.java.interaction.DwMouseDragParticles;

import org.jbox2d.collision.shapes.Shape;
import org.jbox2d.collision.shapes.ShapeType;
import org.jbox2d.collision.shapes.CircleShape;
import org.jbox2d.collision.shapes.PolygonShape;
import org.jbox2d.collision.shapes.ChainShape;
import org.jbox2d.common.MathUtils;
import org.jbox2d.common.Vec2;
import org.jbox2d.common.Transform;
import org.jbox2d.common.Settings;
import org.jbox2d.dynamics.Body;
import org.jbox2d.dynamics.BodyDef;
import org.jbox2d.dynamics.BodyType;
import org.jbox2d.dynamics.Fixture;
import org.jbox2d.dynamics.FixtureDef;
import org.jbox2d.dynamics.joints.JointEdge;
import org.jbox2d.dynamics.joints.WeldJoint;
import org.jbox2d.dynamics.joints.WeldJointDef;
import org.jbox2d.dynamics.contacts.ContactEdge;
import org.jbox2d.particle.ParticleGroup;
import org.jbox2d.particle.ParticleGroupDef;
import org.jbox2d.particle.ParticleType;

import processing.core.*;
import processing.opengl.PGraphics2D;

import gab.opencv.*;
import KinectPV2.*;

int minD = 0;
int maxD = 800;

KinectPV2 kinect;
OpenCV opencv;
float polygonFactor = 5;
int threshold = 200;

//int viewport_w = 1800;
//int viewport_h = 950;
//int viewport_x = 1400;
//int viewport_y = -300;
int viewport_w = 1366;
int viewport_h = 768;
int viewport_x = 0;
int viewport_y = 0;

float worldScale = 10.0;
float kinectScale = 2.67;

boolean UPDATE_PHYSICS = false;
boolean USE_DEBUG_DRAW = false;

DwWorld world;
Body ground;
ArrayList<Body> bodyKillBuffer;
ArrayList<Body> bodyKillBuffer2;

DwParticleEmitter rain;
DwParticleDestroyer unRain;
int particle_counter = 0;
int rainTimer;

ArrayList<Body> SilCollisionPoints;
float silCollPtsThreshold = 20;
int silCollPtsDeltaTime[];
Vec2 silCollPtsPrevPos[];
Vec2 silCollPtsAvgPos[];

ArrayList<SilStructure> SilObjs;
int structPrereqTime = 90;

ArrayList<Flora> FloraObjs;
int bushNum, cattailNum, coniferNum, flowerNum, gladiolusNum;

ArrayList<Shade> ShadeList;

boolean drawStroke = false;
boolean drawFill = true;

////////////////////////////////////////////
/////////////      SETUP      //////////////
////////////////////////////////////////////

void setup() {
  //size(1366, 768, P2D);
  fullScreen(P2D);
  smooth(4);

  opencv = new OpenCV(this, 512, 424);

  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableSkeletonDepthMap(true);
  //kinect.enableDepthImg(true);
  //kinect.enablePointCloud(true);
  kinect.init();

  surface.setLocation(viewport_x, viewport_y);
  reset();

  frameRate(30);
  rectMode(CORNER);
  imageMode(CENTER);
}

void release() {
  if (world != null) world.release(); 
  world = null;
}

void reset() {
  // release old resources
  release();

  world = new DwWorld(this, 1);
  world.transform.setScreen(viewport_w, viewport_h, worldScale, viewport_w, viewport_h);
  world.setParticleRadius(3f/worldScale);
  world.setParticleDensity(5f);
  world.setParticleDamping(0);
  world.setParticleGravityScale(10f);
  world.removeAllMouseActions();
  
  bodyKillBuffer = new ArrayList<Body>();
  bodyKillBuffer2 = new ArrayList<Body>();

  // create scene: rigid bodies, particles, etc ...
  SilObjs = new ArrayList<SilStructure>();

  SilCollisionPoints = new ArrayList<Body>();
  silCollPtsDeltaTime = new int[6];
  silCollPtsPrevPos = new Vec2[42];
  silCollPtsAvgPos = new Vec2[6];
  for (int i=0; i<42; i++) {
    InitSilCollisionPoints();
    silCollPtsPrevPos[i] = new Vec2(0, 0);
  }
  for (int i=0; i<6; i++) {
    silCollPtsDeltaTime[i] = 0;
    silCollPtsAvgPos[i] = new Vec2(999, 999);
  }

  FloraObjs = new ArrayList<Flora>();

  rainTimer = 450;

  InitScene();
  InitShade();
}

void InitScene() {

  Body circle;
  
  BodyDef bd = new BodyDef();
  bd.type = BodyType.STATIC;
  bd.position.set(0, 0);

  ground = world.createBody(bd);
  
  PolygonShape shape = new PolygonShape();
  
  //floor
  shape.setAsBox((viewport_w/2+150)/worldScale, 1, new Vec2(viewport_w/2/worldScale, -4), 0);
  ground.createFixture(shape, 0);
  
  //ceiling
  shape.setAsBox((viewport_w/2+150)/worldScale, 1, new Vec2(viewport_w/2/worldScale, (viewport_h+50)/worldScale), 0);
  ground.createFixture(shape, 0);

  //left wall
  shape.setAsBox(1, viewport_h/2/worldScale+6, new Vec2(-150/worldScale, viewport_h/2/worldScale), 0);
  ground.createFixture(shape, 0);

  //right wall
  shape.setAsBox(1, viewport_h/2/worldScale+6, new Vec2((viewport_w+150)/worldScale, viewport_h/2/worldScale), 0);
  ground.createFixture(shape, 0);

  world.bodies.add(ground, true, color(220), true, color(0), 1f);

  Vec2 segment = new Vec2(4, 10);
  
  //create random plants
  bushNum = 0;
  cattailNum = 0;
  coniferNum = 0;
  flowerNum = 0;
  gladiolusNum = 0;
  for (int i=0; i<viewport_w-1; i+=60) {
    if (random(1f)<1.0) {
      AddPlant(random(5), i, 0, true);
    }
  }

  //rain emitter
  int flags = ParticleType.b2_viscousParticle;
  rain = new DwParticleEmitter(world, world.transform);
  rain.setInWorld(viewport_w/2/worldScale, viewport_h/worldScale, 300, -90, color(0, 80, 200), flags);

  unRain = new DwParticleDestroyer(world, world.transform);
  unRain.setBoxShape(viewport_w+300, 50);
}

void InitSilCollisionPoints() {
  Body body;
  BodyDef bd = new BodyDef();
  bd.position.set(0, 0);
  body = world.createBody(bd);
  Shape shape = new CircleShape();
  shape.m_radius = 1.5;
  body.createFixture(shape, 0.01f);
  world.bodies.add(body, false, color(255, 0, 0), false, color(0, 0, 0), 0);
  SilCollisionPoints.add(body);
}

void InitShade() {
  ShadeList = new ArrayList<Shade>();
  PGraphics pg = createGraphics(500, 500);
  pg.beginDraw();
  pg.background(0, 0, 0, 0);
  pg.fill(0);
  pg.noStroke();
  pg.ellipse(250, 250, 300, 300);
  pg.filter(BLUR, 30);
  pg.endDraw();
  
  for (int i=0; i<viewport_w+50; i+=150) {
    Shade shade = new Shade(i, viewport_h);
    shade.setPGraphic(pg);
    
    BodyDef bd = new BodyDef();
    bd.type = BodyType.STATIC;
    Body sensor = world.createBody(bd);
    FixtureDef fd = new FixtureDef();
    PolygonShape shape = new PolygonShape();
    shape.setAsBox(150/2/worldScale, (viewport_h/2-50)/worldScale, new Vec2(i/worldScale, (viewport_h/2+100)/worldScale), 0);
    fd.shape = shape;
    fd.isSensor = true;
    sensor.createFixture(fd);
    world.bodies.add(sensor, false, color(220), false, color(0), 1f);
    
    shade.setSensor(sensor);
    ShadeList.add(shade);
  }  
}

////////////////////////////////////////////
//////////////      DRAW      //////////////
////////////////////////////////////////////

void draw() {
  background(0);
  //image(kinect.getBodyTrackImage(), width/2, height-212);

  //////////
  //JBOX2D//
  //////////

  if (UPDATE_PHYSICS) {
    addParticles();
    //world.update();
  }
  world.update();
  
  rainTimer++;
  if (random(1)<0.01 && ((!UPDATE_PHYSICS && rainTimer>900) || (UPDATE_PHYSICS && rainTimer>450))) { // rain for at least 15 secs, don't rain for at least 30
    rainTimer = 0;
    UPDATE_PHYSICS = !UPDATE_PHYSICS;
  }
  
  float unRainSpeed = 3;
  if (!UPDATE_PHYSICS && rainTimer*unRainSpeed>viewport_h && rainTimer*unRainSpeed<=viewport_h+20) {
    //unRain.begin(viewport_w/2, rainTimer*unRainSpeed);
    unRain.begin(viewport_w/2, viewport_h+20);
  } else if (!UPDATE_PHYSICS && rainTimer*unRainSpeed>viewport_h+20) {
    unRain.end(viewport_w/2, viewport_h+20);
  }

  PGraphics2D canvas = (PGraphics2D) this.g;
  //canvas.background(200);
  canvas.pushMatrix();
  world.applyTransform(canvas);
  if (USE_DEBUG_DRAW) {
    world.displayDebugDraw(canvas);
    // DwDebugDraw.display(canvas, world);
  } else {
    world.display(canvas);
  }
  canvas.popMatrix();

  // info
  int num_bodies    = world.getBodyCount();
  int num_particles = world.getParticleCount();
  String txt_fps = String.format(getClass().getName()+ " [bodies: %d]  [particles: %d]  [fps %6.2f]", num_bodies, num_particles, frameRate);
  surface.setTitle(txt_fps);

  //////////
  //KINECT//
  //////////

  Silhouettes();

  //Display main appendages
  ArrayList<KSkeleton> skeletonArray =  kinect.getSkeletonDepthMap();

  for (int i = 0; i < skeletonArray.size(); i++) {
    KSkeleton skeleton = (KSkeleton) skeletonArray.get(i);
    if (skeleton.isTracked()) {
      KJoint[] bodyPts = skeleton.getJoints();

      color col  = skeleton.getIndexColor();
      fill(col);
      strokeWeight(3);
      stroke(col);
      FindBody(bodyPts, i);
    }
  }

  for (int i = skeletonArray.size(); i<6; i++) {
    for (int j=0; j<7; j++) {
      SilCollisionPoints.get(i*7+j).setTransform(new Vec2(-6, -3), 0);
    }
  }
  
  //for (Shade shade : ShadeList) {
  //  shade.Display();
  //}
  
  if (frameCount%2==0) {
    TestCollisions(); //destroy speedy objs, destroy joints touched by speedy sil
    //UpdateShade();
  } else {
    //TestParticles();
    CullBodies();
  }
  
  if (frameCount%30==0) {
    UpdateFlora();
    DissolveFlora();
  }
  
  if (frameCount%450==0) {
    bushNum = 0;
    cattailNum = 0;
    coniferNum = 0;
    flowerNum = 0;
    gladiolusNum = 0;
  
    for (Flora flo : FloraObjs) {
      switch (flo.species) {
        case BUSH: bushNum++; break;
        case CONIFER: coniferNum++; break;
        case FLOWER: flowerNum++; break;
        case CATTAIL: cattailNum++; break;
        case GLADIOLUS: gladiolusNum++; break;
        default: break;
      }
    }
      
    if (bushNum==0) {
      AddPlant(FloraType.BUSH, int(random(100, viewport_w-100)));
    }
    if (coniferNum==0) {
      AddPlant(FloraType.CONIFER, int(random(100, viewport_w-100)));
    }
    if (flowerNum==0) {
      AddPlant(FloraType.FLOWER, int(random(100, viewport_w-100)));
    }
    if (cattailNum==0) {
      AddPlant(FloraType.CATTAIL, int(random(100, viewport_w-100)));
    }
    if (gladiolusNum==0) {
      AddPlant(FloraType.GLADIOLUS, int(random(100, viewport_w-100)));
    }
  }    
}

void TestCollisions() {
  Body body = world.getBodyList();
  while (body!=null) {
    Body temp = body;
    
    if (temp.getLinearVelocity().length()>40 && temp.getType()==BodyType.DYNAMIC) {
      bodyKillBuffer.add(body);
    }
    
    body = body.getNext();
  }
  
  //for (int i=0; i<SilCollisionPoints.size(); i++) {
  //  if (i%7==2 || i%7==3) {continue;}
  //  Body pt = SilCollisionPoints.get(i);
  //  ContactEdge contact = pt.getContactList();
    
  //  if (contact!=null && contact.other.getType() == BodyType.DYNAMIC) { //if silCollPt is touching plant segment
  //    Vec2 prevPos = silCollPtsPrevPos[i];
  //    Vec2 currPos = pt.getPosition().mul(worldScale);
      
  //    if (dist(prevPos.x, prevPos.y, currPos.x, currPos.y)>25) { //if distance moved of silCollPt is quick
  //      JointEdge ejoint = pt.getContactList().other.getJointList();
        
  //      if ((ejoint)!=null) { //if joint exists
  //        world.destroyJoint(ejoint.joint);
  //      }
  //    }
  //  }
  //}
}

boolean TestParticles(Flora flo) {
  int pcount = world.getParticleCount();
  Vec2[] pverts = world.getParticlePositionBuffer();
  int[] pflags = world.getParticleFlagsBuffer();
  int goodPCount = 0;
  
  for (int i = 0; i<pcount; i++) {
    Vec2 pPos = pverts[i];
    if (pPos.y < flo.WATER_RADIUS.y/worldScale && pPos.x>(flo.POSX-flo.WATER_RADIUS.x)/worldScale && pPos.x<(flo.POSX+flo.WATER_RADIUS.x)/worldScale) {
      //pflags[i] |= ParticleType.b2_zombieParticle;
      goodPCount++;
    }
  }
  
  if (goodPCount>10) {
    flo.water = flo.MAX_WATER;
  }
  
  return (flo.water<=0);
}

void CullBodies() {
  for (int i=FloraObjs.size()-1; i>=0; i--) {
    Flora flo = FloraObjs.get(i);
    
    ArrayList<Body> floBodies = flo.getBodyList();
    
    for (int j=floBodies.size()-1; j>=0; j--) {
      if (bodyKillBuffer.contains(floBodies.get(j))) {
        flo.removeBodyFromList(j);
      } else if (flo.getLifeState()==2 && bodyKillBuffer2.contains(floBodies.get(j))) {
        world.destroyBody(floBodies.get(j));
        flo.removeBodyFromList(j);
      }
    }
    
    if (floBodies.size()==0) {
      FloraObjs.remove(i);
    }
  }
  
  for (Body bod : bodyKillBuffer) {
    world.destroyBody(bod);
  }
  
  bodyKillBuffer.clear();
  bodyKillBuffer2.clear();
}

void UpdateFlora() {
  GrowAll();
  
  for (int i=FloraObjs.size()-1; i>=0; i--) {
    Flora flo = FloraObjs.get(i);
    flo.Update();
    
    ArrayList<Body> floBodies = flo.getBodyList();      
        
    if (flo.getLifeState()==1) { // kill joints
      int timeSinceDeath = flo.age-flo.MAX_AGE;
      float timeToDecay = flo.DECAY_RATE;
      int jointsPerCycle = ceil(floBodies.size()/timeToDecay);
      for (int j=floBodies.size()-1-timeSinceDeath*jointsPerCycle; j>floBodies.size()-1-(timeSinceDeath+1)*jointsPerCycle; j--) {
        if (j<0) {break;}
        JointEdge ejoint = floBodies.get(j).getJointList();
        
        while (ejoint!=null) {
          JointEdge temp = ejoint;
          ejoint = ejoint.next;
          world.destroyJoint(temp.joint);
        }
      }
      
    } else if (flo.getLifeState()==3) { // propagate
      int newPos[] = flo.Propagate();
      for (int j=0; j<newPos.length; j++) {
        AddPlant(flo.species, newPos[j]);
      }
      
    } else if (flo.getLifeState()==4) { //kill remaining bodies
    
      while (floBodies.size()!=0) {
        world.destroyBody(floBodies.get(0));
        flo.removeBodyFromList(0);
      }
      FloraObjs.remove(i);
    }
  }  
}

void DissolveFlora() {
  ContactEdge contact = ground.getContactList();
  while (contact!=null) { //get number of contacts (bodies in vertical column)
    if (contact.other.getType() == BodyType.DYNAMIC) {
      bodyKillBuffer2.add(contact.other);
    }
    ContactEdge temp = contact;
    contact = contact.next;
  }
}

void UpdateShade() {
  for (Shade shade : ShadeList) {
    Body targBody = shade.getSensor();
    Body body = world.getBodyList();
    
    while(body!=targBody) { //iterate through world's bodies until shade is found
      Body tempBody = body.getNext();
      body = tempBody;
    }
    
    ContactEdge contacts = body.getContactList();
    int count = 0;
    
    while (contacts!=null) { //get number of contacts (bodies in vertical column)
      count++;
      ContactEdge temp = contacts.next;
      contacts = temp;
    }
    shade.Update(count);
  }  
}

////////////////////////////////////////////
/////////////      KINECT      /////////////
////////////////////////////////////////////

//Find Body points
void FindBody(KJoint[] bodyPts, int skeletonID) {
  silCollPtsDeltaTime[skeletonID]++;
  FindBodyPoints(bodyPts, KinectPV2.JointType_HandTipLeft, skeletonID*7+0);
  FindBodyPoints(bodyPts, KinectPV2.JointType_HandTipRight, skeletonID*7+1);
  FindBodyPoints(bodyPts, KinectPV2.JointType_FootLeft, skeletonID*7+2);
  FindBodyPoints(bodyPts, KinectPV2.JointType_FootRight, skeletonID*7+3);

  FindBodyPoints(bodyPts, KinectPV2.JointType_Head, skeletonID*7+4);
  FindBodyPoints(bodyPts, KinectPV2.JointType_SpineShoulder, skeletonID*7+5);
  FindBodyPoints(bodyPts, KinectPV2.JointType_SpineBase, skeletonID*7+6);
}

//draw joint
void FindBodyPoints(KJoint[] bodyPts, int bodyPart, int bodyPtID) {
  float jPosX = bodyPts[bodyPart].getX()*kinectScale;
  float jPosY = (424-bodyPts[bodyPart].getY())*kinectScale;
  Vec2 jointPos = SilCollisionPoints.get(bodyPtID).getPosition().mul(worldScale);
  float deltaDist = dist(jPosX, jPosY, jointPos.x, jointPos.y);
  
  silCollPtsPrevPos[bodyPtID] = jointPos;

  //reset silstructure time if joint changes too quick
  if (deltaDist > silCollPtsThreshold) {
    silCollPtsDeltaTime[bodyPtID/7] = 0;
  } 

  //average position is based on spinebase
  if (bodyPtID%7==6) {
    silCollPtsAvgPos[bodyPtID/7] = new Vec2(jPosX, jPosY);
  }

  if (abs(jPosX)>1400) {
    jPosX = -6;
  }
  if (abs(jPosY)>800) {
    jPosY = -3;
  }
  SilCollisionPoints.get(bodyPtID).setTransform(new Vec2(jPosX/worldScale, max(0, jPosY/worldScale)), 0);
}

void Silhouettes() {

  opencv.loadImage(kinect.getBodyTrackImage());
  opencv.gray();
  opencv.threshold(threshold);
  opencv.invert();

  ArrayList<Contour> contours = opencv.findContours(false, false);

  if (contours.size() > 0) {
    ArrayList<PVector> contourMin = new ArrayList<PVector>();

    for (int i=0; i<silCollPtsDeltaTime.length; i++) {

      if (silCollPtsDeltaTime[i] > structPrereqTime) {
        float skeletonContourDist = 999;

        for (Contour contour : contours) {
          contour.setPolygonApproximationFactor(polygonFactor);
          ArrayList<PVector> contourTemp = contour.getPolygonApproximation().getPoints();

          if (contourTemp.size() > 5) {
            displaySilhouette(contourTemp);
          }

          PVector p1 = contourTemp.get(0);
          PVector p2 = contourTemp.get(contourTemp.size()/2);
          float deltaDist = dist(abs(p1.x-p2.x), abs(p1.y-p2.y), silCollPtsAvgPos[i].x, silCollPtsAvgPos[i].y);

          if (deltaDist < skeletonContourDist) {
            skeletonContourDist = deltaDist;
            contourMin = contourTemp;
          }
        }
        createSilStructure(contourMin);
        silCollPtsDeltaTime[i] = 0;
      } else {
        for (Contour contour : contours) {
          contour.setPolygonApproximationFactor(polygonFactor);
          ArrayList<PVector> contourTemp = contour.getPolygonApproximation().getPoints();
          if (contourTemp.size() > 5) {
            displaySilhouette(contourTemp);
          }
        }
      }
    }
  }

  if (frameCount%30==0) {
    for (int i=0; i<SilObjs.size(); i++) {
      SilObjs.get(i).increaseAge();
      if (SilObjs.get(i).getAge() > SilObjs.get(i).maxAge()) {
        world.destroyBody(SilObjs.get(i).getBody());
        SilObjs.remove(i);
      }
    }
  }
}

void displaySilhouette(ArrayList<PVector> contour) {
  strokeWeight(5);
  stroke(200);
  //noStroke();
  //fill(100);
  noFill();
  beginShape();
  for (PVector point : contour) {
    vertex(point.x*kinectScale, (point.y-424)*kinectScale+viewport_h);
  }
  endShape();
}

void createSilStructure(ArrayList<PVector> contour) {
  Vec2 vertices[] = new Vec2[contour.size()];
  if (vertices.length<3) {return;}
  
  for (int i=0; i<vertices.length; i++) {
    vertices[i] = new Vec2(contour.get(i).x*kinectScale/worldScale, (424-contour.get(i).y)*kinectScale/worldScale);
  }

  Body body = null;
  BodyDef bd = new BodyDef();
  bd.type = BodyType.STATIC;
  bd.position.set(0, 0);
  body = world.createBody(bd);
  ChainShape chain = new ChainShape();
  chain.createLoop(vertices, vertices.length);
  body.createFixture(chain, 0.01);
  world.bodies.add(body, true, color(40), true, color(200), 5);
  SilObjs.add(new SilStructure(body));
}

////////////////////////////////////////////
/////////////      JBOX2D      /////////////
////////////////////////////////////////////

Vec2 Screen2World(Vec2 coord) {
  Vec2 newCoord;

  float x = coord.x/worldScale;
  float y = (viewport_h-coord.y)/worldScale;

  newCoord = new Vec2(x, y);
  return newCoord;
}

void addParticles() {
  rain.emit_pos.x = random(0, viewport_w/worldScale);
  rain.emit_vel_jitter = 50;

  if (particle_counter % 1 == 0) { // frequency of activation
    rain.emitParticles(1);
  }
  particle_counter++;
}

void GrowAll() {
  for (Flora flo : FloraObjs) {
    if (flo.getLifeState()!=0 || frameCount/30%flo.GROWTH_RATE!=0 || flo.mature || TestParticles(flo)) {continue;}
    
    ArrayList<Body> floBodies = flo.getBodyList();
    ArrayList<Integer> floGrown = flo.getGrownList();
    ArrayList<FloraSegDef> floSegments = flo.getSegments();
    
    if (floGrown.size()==floSegments.size()) { // plant is done growing
      flo.mature = true;
      if (!flo.setDynamic) {
        Body body = world.getBodyList();
        while (body!=null) {
          Body temp = body.m_next;
          if (floBodies.contains(body)) {
            body.setType(BodyType.DYNAMIC);
          }
          body = temp;
        }
        flo.setDynamic = true;
      }
      continue;
    }
    if (floGrown.size()>floBodies.size()) { // if body gets killed in the middle of growth, the plant dies immediately
      flo.age = flo.MAX_AGE;
      continue;
    }
    
    ArrayList<FloraSegDef> segsToGrow = flo.Grow();
    ArrayList<Body> newBodies = new ArrayList<Body>();
    
    FixtureDef fd = new FixtureDef();
    WeldJointDef jd = new WeldJointDef();
    Vec2 anchor;

    BodyDef bd = new BodyDef();
    bd.type = BodyType.KINEMATIC;
    Body parBody;
  
    for (FloraSegDef segdef : segsToGrow) {
      bd.position.set((flo.getPos().x+segdef.cen.x)/worldScale, (flo.getPos().y+segdef.cen.y)/worldScale);
      bd.setAngle(segdef.ang);
      Body body = world.createBody(bd);
  
      switch (segdef.sType) {
      case CIRCLE: 
        CircleShape cshape = new CircleShape(); 
        cshape.setRadius(segdef.dim.x/worldScale); 
        fd.shape = cshape; 
        break;
      case POLYGON: 
        PolygonShape pshape = new PolygonShape(); 
        pshape.setAsBox(segdef.dim.x/worldScale, segdef.dim.y/worldScale); 
        fd.shape = pshape; 
        break;
      default: 
        break;
      }
  
      fd.density = segdef.density;
      body.createFixture(fd);
      
      parBody = world.getBodyList();
      
      for (int i=floGrown.size()-1; i>=0; i--) {
        if (segdef.parentID == floGrown.get(i)) {
          Body targBody = floBodies.get(i);
          
          while(parBody!=targBody) {
            Body tempBody = parBody.getNext();
            parBody = tempBody;
          }
          break;
        }
      }
      
      anchor = parBody.getPosition();

      jd.initialize(parBody, body, anchor);
      world.createJoint(jd);
      world.bodies.add(body, drawFill, segdef.col, drawStroke, segdef.col, 1f);
      newBodies.add(body);
    }
  
    flo.storeBodyList(newBodies);
  }
}

void AddPlant(FloraType species, int X) {
  switch (species) {
    //case TREE: AddPlant(-1, X, 0, false); break;
    case BUSH: AddPlant(0, X, 0, false); break;
    case CONIFER: AddPlant(1, X, 0, false); break;
    case FLOWER: AddPlant(2, X, 0, false); break;
    case CATTAIL: AddPlant(3, X, 0, false); break;
    case GLADIOLUS: AddPlant(4, X, 0, false); break;
    default: break;
  }
}

void AddPlant(float species, int X, int Y, boolean fullGrown) {
  //if (species==-1) {
  //  FloraObjs.add(0, new Tree(X, Y));
  //} 
  if (floor(species)==0 && species<0.55 && bushNum++<6) {
    FloraObjs.add(0, new Bush(X, Y));
  } else if (floor(species)==1 && species<1.25 && coniferNum++<4) {
    FloraObjs.add(0, new Conifer(X, Y));
  } else if (floor(species)==2 && species<2.99) {
    FloraObjs.add(0, new Flower(X, Y));
  } else if (floor(species)==3 && species<3.70) {
    FloraObjs.add(0, new Cattail(X, Y));
  } else if (floor(species)==4 && species<4.99) {
    FloraObjs.add(0, new Gladiolus(X, Y));
  } else {
    return;
  }

  ArrayList<FloraSegDef> segments = FloraObjs.get(0).InitSegments(fullGrown);
  ArrayList<Body> retFloBodies = new ArrayList<Body>();

  FixtureDef fd = new FixtureDef();
  WeldJointDef jd = new WeldJointDef();
  Vec2 anchor = new Vec2(X/worldScale, Y/worldScale);

  BodyDef bd = new BodyDef();
  bd.type = BodyType.KINEMATIC;
  Body parBody;

  for (FloraSegDef segdef : segments) {
    bd.position.set((X+segdef.cen.x)/worldScale, (Y+segdef.cen.y)/worldScale);
    bd.setAngle(segdef.ang);
    Body body = world.createBody(bd);

    switch (segdef.sType) {
    case CIRCLE: 
      CircleShape cshape = new CircleShape(); 
      cshape.setRadius(segdef.dim.x/worldScale); 
      fd.shape = cshape; 
      break;
    case POLYGON: 
      PolygonShape pshape = new PolygonShape(); 
      pshape.setAsBox(segdef.dim.x/worldScale, segdef.dim.y/worldScale); 
      fd.shape = pshape; 
      break;
    default: 
      break;
    }

    fd.density = segdef.density;
    body.createFixture(fd);
    if (segdef.parentID==-1) {
      parBody = ground;
      anchor = new Vec2(X/worldScale,Y/worldScale);
    } else {
      parBody = retFloBodies.get(segdef.parentID);
    }
    jd.initialize(parBody, body, anchor);
    world.createJoint(jd);
    world.bodies.add(body, drawFill, segdef.col, drawStroke, segdef.col, 1f);
    retFloBodies.add(body);

    anchor = new Vec2((X+segdef.cen.x)/worldScale, (Y+segdef.cen.y)/worldScale);
  }

  FloraObjs.get(0).storeBodyList(retFloBodies);
}

void RemoveFlora() {
  if (FloraObjs.size()>0) {
    Flora plant = FloraObjs.get(FloraObjs.size()-1);
  
    while (plant.getBodyList().size()>0) {
      world.destroyBody(plant.getBodyList().get(0));
      plant.removeBodyFromList(0);
    }
  
    FloraObjs.remove(FloraObjs.size()-1);
  }
}

void RemoveBaseBody() {
  if (FloraObjs.size()>0) {
    world.destroyBody(FloraObjs.get(0).getBodyList().get(0)); 
    FloraObjs.get(0).removeBodyFromList(0);
    if (FloraObjs.get(0).getBodyList().size()==0) {
      FloraObjs.remove(0);
    }
  }
}

////////////////////////////////////////////
/////////////      INPUT      //////////////
////////////////////////////////////////////

void keyReleased() {
  switch (key) {
    case 'q': maxD-=100; break;
    case 'w': maxD+=100; break;
    case 'a': minD-=100; break;
    case 's': minD+=100; break;
    case 't': UPDATE_PHYSICS = !UPDATE_PHYSICS; rainTimer = 0; break;
    case 'r': reset(); break;
    case 'f': USE_DEBUG_DRAW = !USE_DEBUG_DRAW; break;
    case 'g': GrowAll(); break;
    case 'd': RemoveFlora(); break;
    case 'c': RemoveBaseBody(); break;
    default: break;
  }
}

void mouseReleased() {
  AddPlant(random(5), mouseX, viewport_h-mouseY, false);  
}
