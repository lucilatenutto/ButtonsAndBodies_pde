import fisica.*;

// ==========================================================
// =============== VARIABLES GLOBALES =======================
// ==========================================================

FWorld world;
FBox placeholder;

ArrayList<Carta> cartas = new ArrayList<Carta>();

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
  for (int i = 0; i < 1; i++) {
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
  
  println("draw"); //<>//
  placeholder.draw(this);
  println("post draw pre dibujar"); //<>//
  
  println("dibujar"); //<>//
  // Dibujar cuerpos EXCEPTO el placeholder
  // DESPUES DE TERMINAR DE FLIPEAR Y QUERER DIBUJAR LA CARTA SE DESFASA ACÁ
  for (int i = 0; i < world.getBodies().size(); i++) {
    FBody b = (FBody) world.getBodies().get(i);
  
    if (b != placeholder && !isBodyFlipping(b)) {
      b.draw(this);
    }
  }
  println("post dibujar pre flip");

  // Dibujar flips
  if(flipeando) {
    println("actualizar flip");
    for (Carta c : cartas) c.actualizarFlip();
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
  
  if (b != null) {
    for (Carta c : cartas) {
      if (c.cuerpo == b) {
        cartaSeleccionada = c;
        cartaSeleccionada.cuerpo.setStatic(false);
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
    //cartaSeleccionada.cuerpo.setPosition(placeholder.getX(), placeholder.getY());
    cartaSeleccionada.cuerpo.setStatic(true);
    //cartaSeleccionada.cuerpo.setRotation(0);


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

// ==========================================================
// =============== CLASE CARTA ==============================
// ==========================================================

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
  
    // Cambiar tamaño y volver a centrar (evita el corrimiento)
    cuerpo.setWidth(wTemp);
    cuerpo.setHeight(hOriginal);
    cuerpo.setPosition(x, y);
    cuerpo.setRotation(rot);
  
    // --- DIBUJO MANUAL DEL FLIP ---
    pushMatrix();
    translate(x, y);
    rotate(rot);
    imageMode(CENTER);
    image(imagenActual, 0, 0, wTemp, hOriginal);
    popMatrix();
  
    if (flipProgress >= 1) {
  
      estaFlipping = false;
      flipeando = false;
      flipProgress = 0;
  
      cuerpo.setWidth(wOriginal);
      cuerpo.setHeight(hOriginal);

      println("267");
      cuerpo.setPosition(x, y);
      println("269");
      cuerpo.setRotation(rot);
      println("270");
      cuerpo.attachImage(imagenActual);
      
      world.add(cuerpo);
    }
    println("salgo de la funcion");
  }


}
