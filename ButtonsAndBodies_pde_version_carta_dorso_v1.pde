import fisica.*;

// ==========================================================
// =============== VARIABLES GLOBALES =======================
// ==========================================================

FWorld world;
FBox placeholder;

int cantidadCartas = 8;
ArrayList<Carta> cartas = new ArrayList<Carta>();

ArrayList<FCircle> brillitos = new ArrayList<FCircle>();  
int cardCount = 10;                        // Cantidad de "spiders" (entidades principales) a crear al inicio.
int mainSize = 40;                           // Tamaño (diámetro) del cuerpo principal (la "cabeza" de la araña) en píxeles.
int legCount = 5;                           // Cantidad de "patas" por spider (aquí se crean 'legs' como cuerpos separados).
float legSize = 100;                         // Longitud deseada de los joints que unen la cabeza a cada pata.
color bodyColor = #6E0595;                   // Define un color (tipo 'color' de Processing) para los cuerpos principales.
color hoverColor = #F5B502;                  // Color que se usará cuando pase el mouse por encima.


PImage dorso;
PImage[] frentes;

Carta cartaSeleccionada = null;
boolean arrastrando = false;

boolean flipeando = false;



// ==========================================================
// =============== SETUP ====================================
// ==========================================================

void setup() {
  fullScreen();
  smooth();

  // --- Cargar imágenes ---
  dorso = loadImage("Dorso cartas.PNG");

  frentes = new PImage[5];
  frentes[0] = loadImage("La Emperatriz.png");
  frentes[1] = loadImage("El Sol.png");
  frentes[2] = loadImage("El Ermitanio.PNG");
  frentes[3] = loadImage("La justicia.PNG");
  frentes[4] = loadImage("La Luna.png");

  // Redimensionar todo
  int w = 150;
  int h = 230;

  dorso.resize(w, h);
  for (int i = 0; i < frentes.length; i++) frentes[i].resize(w, h);

  // Inicializar Física
  Fisica.init(this);
  world = new FWorld();
  world.setGravity(0, 0);
  world.setEdges();

  // Crear placeholder (zona donde se activa el flip)
  placeholder = new FBox(w + 20, h + 20);
  placeholder.setPosition(width/2, height/2);
  placeholder.setStatic(true);
  placeholder.setFillColor(color(220));
  placeholder.setStrokeColor(color(100));
  placeholder.setStrokeWeight(4);
  placeholder.setGrabbable(false);
  world.add(placeholder);

  // Crear cartas
  for (int i = 0; i < cantidadCartas; i++) {
    float x = random(200, width - 200);
    float y = random(150, height - 150);

    Carta c = new Carta(x, y, w, h, dorso);

    // asignar frente random
    c.setFrente(frentes[int(random(frentes.length))]);

    cartas.add(c);
    world.add(c.cuerpo);
  }
}

// ==========================================================
// =============== DRAW =====================================
// ==========================================================

void draw() {
  background(255); //<>//

  world.step();
  
  placeholder.draw(this); //<>//
   //<>//
  // Dibujar cuerpos EXCEPTO el placeholder //<>//
  ArrayList<FBody> bodies = world.getBodies();
  for (FBody b : bodies) {
    if (b == placeholder) continue;
    if (isBodyFlipping(b)) continue;
  
    b.draw(this);
  }

  // Dibujar flips
  if(flipeando) {
    for (Carta c : cartas) c.actualizarFlip();
  }
  
  for(FCircle cuerpo:  brillitos){
    float vx = cuerpo.getVelocityX();
    float vy = cuerpo.getVelocityY();
    float velo = constrain(map(abs(vx+vy),1,30,0,255),0,255);
    
    cuerpo.setFillColor(color(255,0,0,velo));
  }
}

// ==========================================================
// =============== INTERACCIÓN ==============================
// ==========================================================

void mousePressed() {
  // No tocar cartas en flip
  for (Carta c : cartas) {
    if (c.estaFlipping) return;
  }

  FBody b = world.getBody(mouseX, mouseY); 
  if (b == placeholder) return;
  
  if (b   != null) { //<>//
    for (Carta c : cartas) {
      if (c.cuerpo == b) {
        cartaSeleccionada = c;
        arrastrando = true;
      }
    }
  }
}

void mouseDragged() {
  if (arrastrando && cartaSeleccionada != null) {
    cartaSeleccionada.cuerpo.setPosition(mouseX, mouseY);
  }
}

void mouseReleased() {
  if (cartaSeleccionada == null) return;

  // Si está sobre el placeholder → iniciar flip
  if (estaSobrePlaceholder(cartaSeleccionada)) {

    // centrar
    cartaSeleccionada.cuerpo.setStatic(true);

    // iniciar flip
    cartaSeleccionada.flip();
  }
   
  cartaSeleccionada = null;
  arrastrando = false;
}

boolean estaSobrePlaceholder(Carta c) {
  float cx = c.cuerpo.getX();
  float cy = c.cuerpo.getY();
  float cw = c.wOriginal;
  float ch = c.hOriginal;

  float px = placeholder.getX();
  float py = placeholder.getY();
  float pw = placeholder.getWidth();
  float ph = placeholder.getHeight();

  return (cx + cw/2 > px - pw/2 &&
          cx - cw/2 < px + pw/2 &&
          cy + ch/2 > py - ph/2 &&
          cy - ch/2 < py + ph/2);
}

// Devuelve true si el body corresponde a una Carta que está flippando
boolean isBodyFlipping(FBody body) {
  for (Carta c : cartas) {
    if (c.cuerpo == body && c.estaFlipping) {
      return true;
    }
  }
  return false;
}

class Carta {

  FBox cuerpo;

  PImage imagenActual;
  PImage imagenFrente;

  boolean estaFlipping = false;
  float flipProgress = 0;

  float wOriginal, hOriginal;

  Carta(float x, float y, float w, float h, PImage imgInicial) {
    wOriginal = w;
    hOriginal = h;

    imagenActual = imgInicial;

    cuerpo = new FBox(w, h);
    cuerpo.setPosition(x, y);
    cuerpo.setDensity(0.1);
    cuerpo.setRestitution(0.3);
    cuerpo.attachImage(imagenActual);
    
      for (int i=0; i<legCount; i++) {            // Bucle para crear cada "pata" asociada a esta cabeza.
        float xx = legSize * cos(i*TWO_PI/3) + x; 
        // Calcula una posición objetivo X para la pata usando coseno. 
        // NOTA: aquí se usa i*TWO_PI/3 (ver nota al final: probablemente querías i*TWO_PI/legCount).
        float yy = legSize * sin(i*TWO_PI/3) + y;
        // Calcula la posición objetivo Y usando seno. Se usa el mismo ángulo que en X.
    
        FCircle leg = new FCircle(mainSize/2);   // Crea la "pata" como un círculo más pequeño (radio = mainSize/2).
        leg.setPosition(x, y);             // Inicialmente sitúa la pata en la misma posición de la cabeza.
        leg.setVelocity(random(-20,20), random(-20,20)); // Le da una velocidad inicial aleatoria.
        leg.setFillColor(bodyColor);              // Mismo color que el cuerpo principal.
        leg.setNoStroke();                         // Sin borde en el dibujo.
        leg.setGrabbable(false);
        world.add(leg);   // Añade la pata al mundo como cuerpo independiente.
        brillitos.add(leg);
    
        FDistanceJoint j = new FDistanceJoint(cuerpo, leg); // Crea un joint de distancia entre main (cabeza) y leg.
        j.setLength(legSize);                     // Establece la longitud del joint (distancia objetivo) a legSize.
        j.setNoStroke();                          // Quita el trazo del joint (si lo dibuja).
        j.setStroke(0);                           // Define el ancho del trazo (0 aquí).
        j.setFill(0);                             // Define relleno (no es muy relevante para joints de línea).
        j.setDrawable(false);                     // Inicialmente no dibuja el joint (se usa mouseMoved para mostrarlo).
        j.setFrequency(0.5);                      // Controla la "frecuencia" / respuesta del joint (afecta comportamiento tipo resort).
        world.add(j);                             // Añade el joint al mundo para que actúe en la simulación.
    }
  }

  void setFrente(PImage img) {
    imagenFrente = img;
  }

  // ----------------- INICIAR FLIP ------------------
  void flip() {
    if (estaFlipping) return;

    estaFlipping = true;
    flipeando = true;
    flipProgress = 0;

    // Sacar del mundo para modificar tamaño
    world.remove(cuerpo);
    
    cuerpo.setPosition(placeholder.getX(), placeholder.getY());
  }

  // ----------------- ACTUALIZAR FLIP ------------------
  void actualizarFlip() {
    if (!estaFlipping) return; //<>//
  
    flipProgress += 0.05;   //<>//
  
    float scaleX;
  
    if (flipProgress < 0.5) {
      scaleX = map(flipProgress, 0, 0.5, 1, 0);
    } else {
      if (imagenFrente != null) imagenActual = imagenFrente;
      scaleX = map(flipProgress, 0.5, 1, 0, 1);
    }
  
    float wTemp = max(wOriginal * scaleX, 2);
  
    // Siempre anclar al placeholder durante la animación
    float x = placeholder.getX();
    float y = placeholder.getY();
    float rot = 0;
  
    // --- DIBUJO MANUAL DEL FLIP ---
    pushMatrix();
    translate(x, y);
    rotate(rot);
    imageMode(CENTER);
    image(imagenActual, 0, 0, wTemp, hOriginal);
    popMatrix();
    imageMode(CORNER);

    if (flipProgress >= 1) {
      cuerpo.attachImage(imagenActual);  
      cuerpo.setStatic(false);
      world.add(cuerpo);
  
      estaFlipping = false;
      flipeando = false;
      flipProgress = 0;  
    }
  }


}
