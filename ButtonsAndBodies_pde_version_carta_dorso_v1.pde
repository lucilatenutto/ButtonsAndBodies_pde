import fisica.*;

// ====================================================================
// === VARIABLES GLOBALES ===
// ====================================================================

FWorld world;                                // Mundo físico de Fisica (Box2D)

// --- Animación de Flip ---
boolean animandoFlip = false;
FBox cartaFlipping = null;   // La carta que actualmente está girando
float flipProgress = 0;      // 0 -> inicio, 1 -> fin

PImage[] frentes;           // Arreglo de imágenes frontales
int frenteElegido = -1;      // Índice de la carta a mostrar

FBox placeholder;           // Caja estática central
FBody cartaSeleccionada = null; // Carta siendo arrastrada
boolean arrastrando = false;

// Tamaños originales de las cartas para la simulación del flip
float originalCardWidth;
float originalCardHeight;

// Colores
color bodyColor = #6E0595;                   
color hoverColor = #F5B502;                  

PImage dorsoCarta; // Imagen del dorso de la carta

// Parámetros de creación
int cardCount = 10;                       
int mainSize = 40;                           
int legCount = 5;  // Patas (Comentado en createCard)
float legSize = 100;

ArrayList<FBody> mains = new ArrayList<FBody>();           // Cuerpos principales (Cartas)
ArrayList<FCircle> brillitos = new ArrayList<FCircle>();  // Patas (Si se usan)

// ====================================================================
// === SETUP Y DRAW ===
// ====================================================================

void setup() {
  fullScreen();
  smooth();                                 

  // --- 1. Inicialización de tamaños ---
  originalCardWidth = mainSize * 1.7;
  originalCardHeight = mainSize * 3;

  // --- 2. Carga y Redimensión de Imágenes ---
  // Asegúrate de que las rutas de las imágenes sean correctas
  dorsoCarta = loadImage("Dorso cartas.PNG"); 
  dorsoCarta.resize(int(originalCardWidth), int(originalCardHeight));
 
  frentes = new PImage[5];
  frentes[0] = loadImage("La Emperatriz.png");
  frentes[1] = loadImage("El Sol.png");
  frentes[2] = loadImage("El Ermitanio.PNG");
  frentes[3] = loadImage("La justicia.PNG");
  frentes[4] = loadImage("La Luna.png");
  
  for (int i=0; i<frentes.length; i++) {
    frentes[i].resize(int(originalCardWidth), int(originalCardHeight));
  }

  // --- 3. Inicialización de Fisica ---
  Fisica.init(this);                         
  world = new FWorld();                     
  world.setEdges();                         
  world.setGravity(0, 0);                   

  // --- 4. Crear Placeholder ---
  float pw = 150;   // ancho
  float ph = 220;   // alto
  
  placeholder = new FBox(pw, ph);
  placeholder.setPosition(width/2, height/2);
  placeholder.setStatic(true);         
  placeholder.setFillColor(color(230));
  placeholder.setStrokeColor(color(120));
  placeholder.setStrokeWeight(3);
  placeholder.setGrabbable(false);
  world.add(placeholder);

  // --- 5. Crear Cartas ---
  for (int i=0; i<cardCount; i++) {        
    createCard();                          
  }
}

void draw() {
  background(255);                           
  world.step();                             
  world.draw();                             
  
  // --- Animación de brillo (brillitos) ---
  for(FCircle cuerpo:  brillitos){
    float vx = cuerpo.getVelocityX();
    float vy = cuerpo.getVelocityY();
    float velo = constrain(map(abs(vx) + abs(vy), 1, 30, 0, 255), 0, 255);
    cuerpo.setFillColor(color(255, 0, 0, velo)); 
  }
  
  // --- Animación de flip (Volteo de Carta) ---
  if (animandoFlip && cartaFlipping != null) {
    
    flipProgress += 0.05;
  
    float scaleX;
    if (flipProgress < 0.5) {
      scaleX = map(flipProgress, 0, 0.5, 1, 0);
    } else {
      if (frenteElegido != -1) {
        cartaFlipping.attachImage(frentes[frenteElegido]);
      }
      scaleX = map(flipProgress, 0.5, 1, 0, 1);
    }
  
    float anchoTemporal = max(originalCardWidth * scaleX, 3);
  
    // 1. Guardamos datos
    float x = cartaFlipping.getX();
    float y = cartaFlipping.getY();
    float rot = cartaFlipping.getRotation();
  
    // 2. CAMBIAMOS el tamaño (carta ya está fuera del mundo porque flipCard la removió)
    cartaFlipping.setWidth(anchoTemporal);
    cartaFlipping.setHeight(originalCardHeight);
  
    // 3. Dibujamos manualmente porque NO está en world.draw()
    pushMatrix();
    translate(x, y);
    rotate(rot);
    imageMode(CENTER);
    //image(cartaFlipping.getImage(), 0, 0, anchoTemporal, originalCardHeight);
    popMatrix();
  
    // FIN DEL FLIP
    if (flipProgress >= 1) {
      animandoFlip = false;
      flipProgress = 0;
  
      // Restaurar tamaño final
      cartaFlipping.setWidth(originalCardWidth);
      cartaFlipping.setHeight(originalCardHeight);
  
      // REINSERTAR al mundo UNA SOLA VEZ
      world.add(cartaFlipping);
      cartaFlipping.setPosition(x, y);
      cartaFlipping.setRotation(rot);
  
      cartaFlipping = null;
    }
  }

}


// ====================================================================
// === FUNCIONES DE JUEGO Y MOUSE ===
// ====================================================================

void createCard() {
  float posX = random(originalCardWidth/2, width-originalCardWidth/2);
  float posY = random(originalCardHeight/2, height-originalCardHeight/2);

  FBox main = new FBox(originalCardWidth, originalCardHeight);
  main.setPosition(posX, posY);
  main.setVelocity(random(-20,20), random(-20,20));
 
  main.attachImage(dorsoCarta);
 
  main.setNoStroke();
  main.setGroupIndex(2);
  world.add(main);

  mains.add(main);
}

void flipCard(FBox carta, int indexFrente) {
  if (!animandoFlip) {
    cartaFlipping = carta;
    frenteElegido = indexFrente;
    flipProgress = 0;
    animandoFlip = true;

    // SACAR del mundo durante el flip para evitar errores Box2D
    world.remove(cartaFlipping);
  }
}


void mousePressed() {
  FBody b = world.getBody(mouseX, mouseY);

  // Solo se puede arrastrar si NO hay una animación de flip en curso
  if (!animandoFlip && b != null && mains.contains(b)) {
    cartaSeleccionada = b;
    
    // Si estaba fija, la liberamos para arrastrarla
    cartaSeleccionada.setStatic(false); 
    arrastrando = true;
  }
}


void mouseDragged() {
  if (arrastrando && cartaSeleccionada != null) {
    cartaSeleccionada.setPosition(mouseX, mouseY);
  }
}

void mouseReleased() {
  if (cartaSeleccionada != null) {

    if (estaSobrePlaceholder(cartaSeleccionada)) {
      // 1. Colocar perfectamente al centro del placeholder
      cartaSeleccionada.setPosition(placeholder.getX(), placeholder.getY());

      // 2. Fijar la carta (la hacemos estática)
      cartaSeleccionada.setStatic(true);
      
      // 3. INICIA LA ANIMACIÓN DE FLIP
      // Elegimos un frente aleatorio
      int nuevoFrente = int(random(frentes.length)); 
      flipCard((FBox)cartaSeleccionada, nuevoFrente); 

    } 
    else {
      // Si no está en el placeholder, se mueve libre
      cartaSeleccionada.setStatic(false);
    }

    cartaSeleccionada = null;
    arrastrando = false;
  }
}

boolean estaSobrePlaceholder(FBody carta) {
  float cx = carta.getX();
  float cy = carta.getY();
  float cw = ((FBox)carta).getWidth(); 
  float ch = ((FBox)carta).getHeight();

  float px = placeholder.getX();
  float py = placeholder.getY();
  float pw = placeholder.getWidth();
  float ph = placeholder.getHeight();

  // chequeo AABB
  return (cx + cw/2 > px - pw/2 &&
          cx - cw/2 < px + pw/2 &&
          cy + ch/2 > py - ph/2 &&
          cy - ch/2 < py + ph/2);
}

// Funciones auxiliares (manteniendo las originales)
void setJointsColor(FBody b, color c) {
  ArrayList l = b.getJoints();
  for (int i=0; i<l.size(); i++) {
    FJoint j = (FJoint)l.get(i);
    j.setStrokeColor(c);
    j.setFillColor(c);
    j.getBody1().setFillColor(c);
    j.getBody2().setFillColor(c);
  }
}

void setJointsDrawable(FBody b, boolean c) {
  ArrayList l = b.getJoints();
  for (int i=0; i<l.size(); i++) {
    FJoint j = (FJoint)l.get(i);
    j.setDrawable(c);
  }
}
