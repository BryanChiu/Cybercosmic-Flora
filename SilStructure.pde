class SilStructure {
  int MAX_AGE;
  
  Body sil;
  int age;
  
  SilStructure(Body body) {
    this.sil = body;
    this.MAX_AGE = 15;
  }
  
  void increaseAge() {
    age++;
  }
  
  int getAge() {
    return age;
  }
  
  int maxAge() {
    return MAX_AGE;
  }
  
  Body getBody() {
    return sil;
  }
}
