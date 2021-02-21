abstract class Flora {
  FloraType species;
  int POSX;
  int POSY;
  int MAX_AGE; //in seconds
  int GROWTH_RATE; // in seconds between growth
  int DECAY_RATE; // in seconds to fully decay (joints breaking)
  int FERTILITY;
  int SPREAD;
  int MAX_WATER;
  Vec2 WATER_RADIUS;
  
  int age;
  int water;
  boolean mature;
  boolean setDynamic;
  
  ArrayList<FloraSegDef> Segments; //arraylist<> for shape data, in order of ID
  ArrayList<Body> BodyList; //arraylist<body> for actual bodies
  ArrayList<Integer> SegGrownList; // list of IDs of segments grown
  
  abstract ArrayList<FloraSegDef> InitSegments(boolean fullGrown);
  
  abstract void BranchOff(FloraSegDef parent, int maxLength);
  
  ArrayList<FloraSegDef> Grow() {    
    ArrayList<FloraSegDef> returnList = new ArrayList<FloraSegDef>();

    for (int i=Segments.size()-1; i>0; i--) {
      if (SegGrownList.contains(Segments.get(i).parentID) && !SegGrownList.contains(i)) {
        returnList.add(0, Segments.get(i));
      }
    }
    
    for (FloraSegDef seg : returnList) {
      SegGrownList.add(seg.ID);
    }
      
    return returnList;
  }
  
  int[] Propagate() {
    if (!mature) {
      return new int[0];
    }
    int numKids = int(random(1, FERTILITY+1)) - int(random(4))/3;
    int litter[] = new int[numKids];
    
    for (int i=0; i<numKids; i++) {
      litter[i] = POSX+int(random(-SPREAD, SPREAD));
    }
    
    return litter;
  }
  
  void Update() {
    age++;
    water--;
    if (water<0) {
      water = 0;
    } else if (water > MAX_WATER) {
      water = MAX_WATER;
    }
  }
    
  void storeBodyList(ArrayList<Body> bodies) {
    BodyList.addAll(bodies);
  }

  ArrayList<Body> getBodyList() {
    return BodyList;
  }

  ArrayList<FloraSegDef> getSegments() {
    return Segments;
  }

  ArrayList<Integer> getGrownList() {
    return SegGrownList;
  }

  void removeBodyFromList(int index) {
    BodyList.remove(index);
  }

  Vec2 getPos() {
    return new Vec2(POSX, POSY);
  }
  
  abstract int getLifeState();
  
  int getAge() {
    return age;
  }
}

public enum FloraType {
  BUSH, CATTAIL, CONIFER, FLOWER, GLADIOLUS
}
