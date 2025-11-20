import fisica.*;

import fisica.*;                             // Importa todas las clases de la librería Fisica (wrapper de Box2D para Processing).

FWorld world;                                // Declara una variable global para el "mundo físico" donde viven los cuerpos.

FBox placeholder;
FBody cartaSeleccionada = null;
boolean arrastrando = false;

color bodyColor = #6E0595;                   // Define un color (tipo 'color' de Processing) para los cuerpos principales.
color hoverColor = #F5B502;                  // Color que se usará cuando pase el mouse por encima.

PImage dorsoCarta; // Declara la variable PImage

int cardCount = 10;                        // Cantidad de "spiders" (entidades principales) a crear al inicio.
int mainSize = 40;                           // Tamaño (diámetro) del cuerpo principal (la "cabeza" de la araña) en píxeles.
int legCount = 5;                           // Cantidad de "patas" por spider (aquí se crean 'legs' como cuerpos separados).
float legSize = 100;                         // Longitud deseada de los joints que unen la cabeza a cada pata.

ArrayList mains = new ArrayList();           // Lista que guardará los cuerpos principales creados (raw ArrayList sin generics).
ArrayList<FCircle> brillitos = new ArrayList<FCircle>();  

void setup() {
  //size(1400, 700);                            // Crea la ventana de dibujo de 400x400 px.
  fullScreen();
  smooth();                                  // Activa el antialiasing para dibujado más suave.

  dorsoCarta = loadImage("Dorso cartas.PNG"); // Carga el archivo de imagen

  Fisica.init(this);                         // Inicializa la librería Fisica pasándole la instancia de sketch (obligatorio).

  world = new FWorld();                      // Crea un nuevo mundo físico.
  world.setEdges();                          // Crea los bordes (limitadores) del mundo: top/bottom/left/right por defecto.
  world.setGravity(0, 0);                    // Establece la gravedad en el mundo: (0,0) = sin gravedad horizontal ni vertical.

  // Crear placeholder en el centro
  float pw = 150;   // ancho
  float ph = 220;   // alto
  
  placeholder = new FBox(pw, ph);
  placeholder.setPosition(width/2, height/2);
  placeholder.setStatic(true);         // No se mueve
  placeholder.setFillColor(color(230));
  placeholder.setStrokeColor(color(120));
  placeholder.setStrokeWeight(3);
  
  placeholder.setGrabbable(false);
  placeholder.setStatic(true);
  
  world.add(placeholder);


  for (int i=0; i<cardCount; i++) {        // Bucle para crear 'spiderCount' spiders al inicio.
    createCard();                          // Llama a la función que crea una spider (cuerpo principal + patas).
  }
}

void draw() {
  background(255);                           // Limpia la pantalla con fondo blanco.
  world.step();                              // Avanza la simulación física un paso (actualiza posiciones/velocidades).
  world.draw();                              // Dibuja todos los cuerpos y joints del mundo en el canvas.
  
  for(FCircle cuerpo:  brillitos){
    float vx = cuerpo.getVelocityX();
    float vy = cuerpo.getVelocityY();
    float velo = constrain(map(abs(vx+vy),1,30,0,255),0,255);
    
    cuerpo.setFillColor(color(255,0,0,velo));
  }
}

void createCard() {
  float posX = random(mainSize/2, width-mainSize/2);   // Elige una posición X aleatoria dentro del canvas, evitando que la cabeza salga de los bordes.
  float posY = random(mainSize/2, height-mainSize/2);  // Lo mismo para la posición Y.

  FBox main = new FBox(mainSize*1.7,mainSize*3);       // Crea un cuerpo circular (la "cabeza") de diámetro mainSize.
  main.setPosition(posX, posY);               // Coloca la cabeza en (posX, posY).
  main.setVelocity(random(-20,20), random(-20,20)); // Le da una velocidad inicial aleatoria (x,y).
 
  dorsoCarta.resize(int(mainSize*1.7), int(mainSize*3));
  main.attachImage(dorsoCarta);
 
  main.setNoStroke();                         // Quita el borde al dibujarlo.
  main.setGroupIndex(2);                      // Asigna un índice de grupo para control de colisiones (ver nota más abajo).
  world.add(main);                            // Añade el cuerpo principal al mundo físico.

  mains.add(main);                            // Almacena la referencia en la lista 'mains' para poder interactuar con él luego.

  for (int i=0; i<legCount; i++) {            // Bucle para crear cada "pata" asociada a esta cabeza.
    float x = legSize * cos(i*TWO_PI/3) + posX; 
    // Calcula una posición objetivo X para la pata usando coseno. 
    // NOTA: aquí se usa i*TWO_PI/3 (ver nota al final: probablemente querías i*TWO_PI/legCount).
    float y = legSize * sin(i*TWO_PI/3) + posY;
    // Calcula la posición objetivo Y usando seno. Se usa el mismo ángulo que en X.

    FCircle leg = new FCircle(mainSize/2);   // Crea la "pata" como un círculo más pequeño (radio = mainSize/2).
    leg.setPosition(posX, posY);             // Inicialmente sitúa la pata en la misma posición de la cabeza.
    leg.setVelocity(random(-20,20), random(-20,20)); // Le da una velocidad inicial aleatoria.
    leg.setFillColor(bodyColor);              // Mismo color que el cuerpo principal.
    leg.setNoStroke();                         // Sin borde en el dibujo.
    leg.setGrabbable(false);
    world.add(leg);   // Añade la pata al mundo como cuerpo independiente.
    brillitos.add(leg);

    FDistanceJoint j = new FDistanceJoint(main, leg); // Crea un joint de distancia entre main (cabeza) y leg.
    j.setLength(legSize);                     // Establece la longitud del joint (distancia objetivo) a legSize.
    j.setNoStroke();                          // Quita el trazo del joint (si lo dibuja).
    j.setStroke(0);                           // Define el ancho del trazo (0 aquí).
    j.setFill(0);                             // Define relleno (no es muy relevante para joints de línea).
    j.setDrawable(false);                     // Inicialmente no dibuja el joint (se usa mouseMoved para mostrarlo).
    j.setFrequency(0.5);                      // Controla la "frecuencia" / respuesta del joint (afecta comportamiento tipo resort).
    world.add(j);                             // Añade el joint al mundo para que actúe en la simulación.
  }
}

void setJointsColor(FBody b, color c) {
  ArrayList l = b.getJoints();                // Recupera la lista de joints asociados al cuerpo 'b'.

  for (int i=0; i<l.size(); i++) {            // Recorre esa lista de joints.
    FJoint j = (FJoint)l.get(i);              // Castea cada elemento a FJoint.
    j.setStrokeColor(c);                      // Cambia el color del trazo del joint.
    j.setFillColor(c);                        // Cambia el color de relleno del joint (si aplica).
    j.getBody1().setFillColor(c);             // Cambia el color del primer cuerpo conectado por el joint.
    j.getBody2().setFillColor(c);             // Cambia el color del segundo cuerpo conectado por el joint.
    // Nota: esto pinta también los cuerpos conectados: útil para destacar visualmente la conexión.
  }
}

void setJointsDrawable(FBody b, boolean c) {
  ArrayList l = b.getJoints();                // Recupera los joints del cuerpo 'b'.

  for (int i=0; i<l.size(); i++) {            // Recorre todos los joints.
    FJoint j = (FJoint)l.get(i);              // Castea el elemento a FJoint.
    j.setDrawable(c);                         // Activa/desactiva el dibujo del joint según el booleano 'c'.
  }
}

void mousePressed() {
  FBody b = world.getBody(mouseX, mouseY);

  // Solo podemos agarrar cartas, no patas ni placeholder
  if (b != null && mains.contains(b)) {

    cartaSeleccionada = b;

    // Si estaba fija dentro del placeholder, la volvemos dinámica para sacarla
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
      // Colocar perfectamente al centro del placeholder
      cartaSeleccionada.setPosition(placeholder.getX(), placeholder.getY());

      // Fijar la carta para que NO se mueva
      cartaSeleccionada.setStatic(true);
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

  // chequeo AABB (Axis-Aligned Bounding Box)
  return (cx + cw/2 > px - pw/2 &&
          cx - cw/2 < px + pw/2 &&
          cy + ch/2 > py - ph/2 &&
          cy - ch/2 < py + ph/2);
}
