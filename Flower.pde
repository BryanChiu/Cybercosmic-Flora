class Flower extends Flora {
  color stemCol = color(50, 150, 50);

  Flower(int _POSX, int _POSY) {
    this.species = FloraType.FLOWER;
    this.POSX = _POSX;
    this.POSY = _POSY;

    this.age = 0;
    this.MAX_AGE = 45+int(random(-10, 10));
    this.GROWTH_RATE = 1;
    this.DECAY_RATE = 2;
    this.FERTILITY = 2;
    this.SPREAD = 50;
    this.water = 1;
    this.MAX_WATER = 2;
    this.WATER_RADIUS = new Vec2(30, 30);
    this.mature = false;
    this.setDynamic = false;

    Segments = new ArrayList<FloraSegDef>();
    BodyList = new ArrayList<Body>();
    SegGrownList = new ArrayList<Integer>();
  }

  ArrayList<FloraSegDef> InitSegments(boolean fullGrown) {
    ArrayList<FloraSegDef> returnList = new ArrayList<FloraSegDef>();
    Vec2 segdim = new Vec2(1.5, 2);
    FloraSegDef segdef;
    int parentID;

    float angle = random(-PI/90, PI/90);

    //stem
    int plantHeight = int(random(4, 7));

    Vec2 branchVec = new Vec2(cos(angle+PI/2)*segdim.y, sin(angle+PI/2)*segdim.y);
    parentID = -1;

    for (int i = 0; i < plantHeight; ++i) {
      Vec2 cen = new Vec2(branchVec.x+branchVec.x*2*i, branchVec.y+branchVec.y*2*i);
      segdef = new FloraSegDef(Segments.size(), parentID, ShapeType.POLYGON, 30, cen, segdim, angle, new Colour().offset(stemCol, 40));
      Segments.add(segdef);

      if (parentID==-1 && !fullGrown) {
        returnList.add(segdef);
        SegGrownList.add(Segments.size()-1);
      }

      if (random(1f)<0.5 && i<plantHeight-1) {
        BranchOff(segdef, 1);
      }

      parentID = segdef.ID;
    }

    //bulb/head
    Vec2 cen = new Vec2(branchVec.x+branchVec.x*2*plantHeight, branchVec.y+branchVec.y*2*plantHeight);
    segdef = new FloraSegDef(Segments.size(), parentID, ShapeType.CIRCLE, 2, cen, new Vec2(5, 5), 0f, color(random(255), random(255), random(255)));
    Segments.add(segdef);

    if (fullGrown) {
      for (int i=0; i<Segments.size(); i++) {
        SegGrownList.add(i);
      }
      return Segments;
    }

    return returnList;
  }

  void BranchOff(FloraSegDef parent, int maxLength) {
    FloraSegDef segdef;
    Vec2 segdim = new Vec2(2.5, 3);
    int parentID = parent.ID;
    int branchLength = maxLength;
    int leftright = int(random(2))*2-1;
    float angle = leftright*random(2*PI/8, 3*PI/8)+parent.ang;
    Vec2 branchVec = new Vec2(cos(angle+PI/2)*segdim.y, sin(angle+PI/2)*segdim.y);
    Vec2 cen = new Vec2(branchVec.x+parent.cen.x, branchVec.y+parent.cen.y);

    segdef = new FloraSegDef(Segments.size(), parentID, ShapeType.POLYGON, 5, cen, segdim, angle, new Colour().offset(stemCol, 40));
    Segments.add(segdef);

    parentID = segdef.ID;
  }

  int getLifeState() {
    if (age<MAX_AGE) return 0; // still living
    if (age<MAX_AGE+4) return 1; // dead, decaying, bodies w/o joints
    if (age==MAX_AGE+4 && mature) return 3; // propagate if not dead early
    if (age<MAX_AGE+8) return 2; // destroy bodies from world
    return 4;
  }
}
