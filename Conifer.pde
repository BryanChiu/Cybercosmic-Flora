class Conifer extends Flora {
  color trunkCol = color(130, 60, 10);
  color branchCol = color(0, 100, 10);

  Conifer(int _POSX, int _POSY) {
    this.species = FloraType.CONIFER;
    this.POSX = _POSX;
    this.POSY = _POSY;

    this.age = 0;
    this.MAX_AGE = 120+int(random(-10, 10));
    this.GROWTH_RATE = 3;
    this.DECAY_RATE = 12;
    this.FERTILITY = 2;
    this.SPREAD = 150;
    this.water = 3;
    this.MAX_WATER = 10;
    this.WATER_RADIUS = new Vec2(150, 500);
    this.mature = false;
    this.setDynamic = false;

    Segments = new ArrayList<FloraSegDef>();
    BodyList = new ArrayList<Body>();
    SegGrownList = new ArrayList<Integer>();
  }

  ArrayList<FloraSegDef> InitSegments(boolean fullGrown) {
    Vec2 segdim = new Vec2(8, 20);
    FloraSegDef segdef;
    int parentID = -1;

    float angle = random(-PI/64, PI/64);
    Vec2 branchVec = new Vec2(cos(angle+PI/2)*segdim.y, sin(angle+PI/2)*segdim.y);

    //stem
    int plantHeight = int(random(15, 19));
    for (int i = 0; i < plantHeight; ++i) {
      Vec2 cen = new Vec2(branchVec.x+branchVec.x*2*i, branchVec.y+branchVec.y*2*i);

      if (i>plantHeight/2) {
        Vec2 tempDim = new Vec2();
        tempDim.set(constrain(map(i, plantHeight/2, 4*plantHeight/5, 8, 3), 3, 8), segdim.y);
        color tempCol = lerpColor(trunkCol, branchCol, (i-plantHeight/2.0)/(plantHeight/3.0));
        segdef = new FloraSegDef(Segments.size(), parentID, ShapeType.POLYGON, 30, cen, tempDim, angle, new Colour().offset(tempCol, 20));
      } else {
        segdef = new FloraSegDef(Segments.size(), parentID, ShapeType.POLYGON, 50, cen, segdim, angle, new Colour().offset(trunkCol, 20));
      }
      Segments.add(segdef);
      if (random(1f)>0.0 && i>plantHeight/3 && i<plantHeight-1) {
        BranchOff(segdef, plantHeight-i);
      }
      parentID = segdef.ID;
    }

    if (fullGrown) {
      for (int i=0; i<Segments.size(); i++) {
        SegGrownList.add(i);
      }
      return Segments;
    }

    ArrayList<FloraSegDef> returnList = new ArrayList<FloraSegDef>();
    returnList.add(Segments.get(0));
    SegGrownList.add(0); //add first segment to grown list
    return returnList;
  }

  void BranchOff(FloraSegDef parent, int maxLength) {
    if (maxLength==0) return;

    FloraSegDef segdef;
    Vec2 segdim = new Vec2(3, 10);
    int parentID = parent.ID;
    int branchLength = int(random(max(1, maxLength-1), maxLength));
    int leftright = maxLength%2*2-1;
    float angle = leftright*random(7*PI/16, 9*PI/16)+parent.ang;
    Vec2 branchVec = new Vec2(cos(angle+PI/2)*segdim.y, sin(angle+PI/2)*segdim.y);

    for (int i = 0; i < branchLength; ++i) {
      Vec2 cen = new Vec2(branchVec.x+branchVec.x*2*i+parent.cen.x, branchVec.y+branchVec.y*2*i+parent.cen.y);

      segdef = new FloraSegDef(Segments.size(), parentID, ShapeType.POLYGON, 5, cen, segdim, angle, new Colour().offset(branchCol, 20));
      Segments.add(segdef);
      if (random(1f)>0.4) {
        BranchOff(segdef, branchLength-1-i);
      }

      parentID = segdef.ID;
    }
  }
  
  int getLifeState() {
    if (age<MAX_AGE) return 0; // still living
    if (age<MAX_AGE+20) return 1; // dead, decaying, bodies w/o joints
    if (age==MAX_AGE+30 && mature) return 3; // propagate if not dead early
    if (age<MAX_AGE+40) return 2; // destroy bodies from world
    return 4;
  }
}
