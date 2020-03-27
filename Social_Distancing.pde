/* Social Distancing Model
 *   A model created to show the effects of social distancing
 *   on the spread of a sickness. This was created in the middle
 *   of the COVID-19 global pandemic as as way for me to visualize
 *   and experiment with how social distancing works.
 *   
 *   This project was directly inspired from Harry Steven's article:
 *   https://www.washingtonpost.com/graphics/2020/world/corona-simulator/
 *    
 *   Created by Ryan Danver 3/22/20
 */

// One tick is executed per frame.
final int TICKS_PER_SECOND = 60;

// Amount of ticks it takes until sick agent recovers.
final int SICK_TICKS = 500;

// Other agent properties
final float SPEED = 1;
final int DIAMETER = 8;

color healthyColor = color(150, 150, 150);
color sickColor = color(255, 100, 100);
color recoveredColor = color(100, 255, 100);
int L_Field = 300;
ArrayList<Person> agents;
Slider[] sliders;
Button[] buttons;
int ticks;
int infoX, infoY;
boolean run;
boolean clicked;
Table data;

void setup() {
  size(1000, 600);
  background(255);
  frameRate(TICKS_PER_SECOND);
  infoX = 10;
  infoY = height/2;
  ticks = 0;
  run = false;
  agents = new ArrayList<Person>();
  initTable();
  buttons = new Button[] {
    new Button(L_Field/2, infoY-40, 100, 50, "Start / Stop", 15), 
    new Button(L_Field/2, infoY+180, 100, 50, "Save data", 15), 
  };
  sliders = new Slider[] {
    new Slider(L_Field/2, 50, 100, 1, 1500), 
    new Slider(L_Field/2, 125, 100, 1, 500), 
    new Slider(L_Field/2, 200, 100, 0, 1500), 
  };
}

void draw() {
  background(255);
  if (run) {
    ticks++;
    for (Person p : agents) p.update();
    TableRow row = data.addRow();
    row.setInt(0, ticks);
    row.setInt(1, getCount(0));
    row.setInt(2, getCount(1));
    row.setInt(3, getCount(2));
  }
  for (Person p : agents) p.show();
  drawGUI();
}

void mouseClicked() { 
  if (buttons[0].checkConstraints()) {
    run = !run;
    if (run) {
      initTable();
      updateField();
      ticks = 0;
    } else {
    }
  } else if (buttons[1].checkConstraints()) {
    saveTable(data, "data.csv");
  }
}

void drawGUI() {

  // Sliders & buttons
  fill(230);
  noStroke();
  rect(0, 0, L_Field, height);
  stroke(0);
  strokeWeight(4);
  line(L_Field, 0, L_Field, height);
  line(0, infoY, L_Field-1, infoY);
  strokeWeight(1);

  String[] text = new String[]{"Agents: ", "Amount Sick: ", "Amount Quarantined: "};
  textAlign(CENTER);
  for (int i = 0; i < sliders.length; i++) {
    Slider s = sliders[i];
    s.show();
    s.update();
    fill(0);
    text(text[i] + s.value(), s.pos.x, s.pos.y - 20);
  }
  for (Button b : buttons) b.show();
  textAlign(CORNER);

  // Stats / info
  float healthy = getCount(0);
  float sick = getCount(1);
  float recovered = getCount(2);
  float hpc = (healthy != 0) ? healthy/agents.size()*100 : 0;
  float spc = (sick != 0) ? sick/agents.size()*100 : 0;
  float rpc = (recovered != 0) ? recovered/agents.size()*100 : 0;
  float qpc = (getQuarantined() != 0) ? (float) getQuarantined()/agents.size()*100 : 0;
  float[] percents = new float[]{hpc, spc, rpc, qpc };
  float[] nums = new float[]{healthy, sick, recovered};

  textSize(15);
  fill(0);
  text("Ticks: " + ticks, infoX, infoY+20);
  fill(healthyColor);
  ellipse(infoX+2, infoY+55, 15, 15);
  fill(sickColor);
  ellipse(infoX+2, infoY+75, 15, 15);
  fill(recoveredColor);
  ellipse(infoX+2, infoY+95, 15, 15);
  fill(0);
  text("Healthy agents: ", infoX+15, infoY+60);
  text("Sick agents: ", infoX+15, infoY+80);
  text("Recovered agents: ", infoX+15, infoY+100);
  text("Agents quarantined: ", infoX, infoY+120);
  for (int i = 0; i < percents.length; i++) {
    text(nf(percents[i], 2, 2) + "%", L_Field-75, infoY + i*20 + 60);
  }
  for (int i = 0; i < nums.length; i++) {
    text(int(nums[i]), L_Field-120, infoY + i*20 + 60);
  }
}

void updateField() {
  agents = new ArrayList<Person>();
  int hAmount = sliders[0].value() - sliders[1].value();
  addToField((hAmount < 0) ? 0 : hAmount, 0);
  addToField((hAmount < 0) ? sliders[0].value() : sliders[1].value(), 1);

  for (int i = 0; i < sliders[2].value(); i++) {
    if (i < agents.size()) agents.set(i, agents.get(i).quarantined());
  }
}

void addToField(int amount, int stat) {
  int added = 0;
  while (added < amount) {
    PVector pos = new PVector(random(L_Field + DIAMETER, width-DIAMETER), random(DIAMETER, height-DIAMETER));
    boolean filled = false;
    for (Person p : agents)
      if (p.checkCollision(pos)) filled = true;
    if (!filled) {
      agents.add(new Person(pos, PVector.random2D().mult(SPEED), stat, false));
      added++;
    }
  }
}

int getCount(int stat) {
  int found = 0;
  for (Person p : agents) if (p.stat == stat) found++;
  return found;
}

int getQuarantined() {
  int found = 0;
  for (Person p : agents) if (p.quarantine == true) found++;
  return found;
}

void initTable() {
  data = new Table();
  data.addColumn("Tick");
  data.addColumn("Healthy");
  data.addColumn("Sick");
  data.addColumn("Recovered");
}

class Person {
  PVector pos, force;
  int stat, sTicks;
  int r, d;
  boolean quarantine;
  Person(PVector pos, PVector force, int stat, boolean quarantine) {
    this.pos = pos;
    this.stat = stat;
    this.force = force;
    this.quarantine = quarantine;
    d = DIAMETER;
    r = d / 2;
  }

  void show() {
    switch(stat) {
    case 0: fill(healthyColor); break;
    case 1: fill(sickColor); break;
    case 2: fill(recoveredColor); break;
    }
    noStroke();
    ellipse(this.pos.x, this.pos.y, d, d);
  }

  void update() {
    if (stat == 1) {
      sTicks += 1;
      if (sTicks == SICK_TICKS) stat = 2;
    }
    boolean hit = false;
    if (pos.x - r <= L_Field || pos.x + r >= width || pos.y - r <= 0 || pos.y + r >= height) hit = true;
    for (Person p : agents) {
      if (checkCollision(p.pos)) {
        if (stat == 1 && p.stat == 0) p.stat = 1;
        hit = true;
      }
    }
    if (hit)
      force.rotate(PI/2);
    if (!quarantine)
      pos.add(force);
  }

  boolean checkCollision(PVector other) {
    float dist = pos.dist(other);
    if (dist < r + r && dist != 0) return true;
    return false;
  }

  Person quarantined() {
    Person p = this;
    p.quarantine = true;
    return p;
  }
}
class Slider {
  PVector pos;
  float w, h;
  float sw, sh;
  float val;
  int size;
  int min, max;

  Slider(int x, int y, int size, int min, int max) {
    pos = new PVector(x, y);
    this.size = size;
    this.min = min;
    this.max = max;
    w = size*2.5;
    h = size*0.1;
    sw = size/3;
    sh = size/5;
    val = pos.x;
  }

  void show() {
    fill(255);
    rectMode(CENTER);
    rect(pos.x, pos.y, w, h);
  }

  void update() {
    fill(150);
    rect(val, pos.y, sw, sh);
    if (mousePressed) {
      if (mouseX > val - sw/2 && mouseX < val + sw/2 && mouseY > pos.y - sh/2 && mouseY < pos.y + sh/2) {
        val = constrain(mouseX, pos.x - w/2, pos.x + w/2);
      }
    }
  }

  public int value() {
    return int(map(val, pos.x - w/2, pos.x + w/2, min, max));
  }
}

class Button {
  int x, y;
  int w, h;
  String text;
  int textSize;
  color c;
  boolean isClicked;

  Button(int x, int y, int w, int h, String text, int textSize) {
    this.x = x;
    this.y = y;
    this.text = text;
    this.w = w;
    this.h = h;
    this.textSize = textSize;
    isClicked = false;
    c = color(255);
  }

  void show() {
    rectMode(CENTER);
    textAlign(CENTER);
    textSize(textSize);
    fill(c);
    rect(x, y, w, h);
    fill(0);
    text(text, x, y+(textSize/3));
    textAlign(CORNER);
    rectMode(CORNER);
  }

  boolean checkConstraints() {
    if (mouseX > x - w/2 && mouseX < x + w/2 && mouseY > y- h/2 && mouseY < y + h/2) return true;
    return false;
  }
}
