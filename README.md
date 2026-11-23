Cable a Tierra
Entorno virtual narrativo en primera persona, hecho en Godot 4.7 para la materia Creatividad y Desarrollo de Entornos Virtuales (UTN FRC, 2026). Grupo 10.

Un pescador cae al mar en una tormenta y queda en coma. Para despertar, recorre cuatro recuerdos de su vida (la infancia, la adolescencia, la adultez y el accidente), cada uno un poco más roto que el anterior. Los une un barquito de madera que le talló su abuelo: su cable a tierra. El juego nunca dice que el protagonista está en coma: lo cuenta con la luz, el agua y el sonido.

Cómo jugarlo
Instalá Godot Engine 4.7.x, versión estándar (no la .NET), desde godotengine.org/download. Funciona en Windows, Mac y Linux.
Descargá el proyecto: botón Code → Download ZIP en esta página (o git clone https://github.com/FacuWitt/tp_cved_juego.git) y descomprimilo.
Abrí Godot, tocá Importar, elegí la carpeta del proyecto (el archivo project.godot) y Importar y editar. La primera vez tarda un rato en importar los modelos, las texturas y los sonidos.
Apretá F5. El juego arranca en la Memoria 1 y sigue solo hasta el final.
Dura unos 10 minutos. Se recomienda jugarlo con auriculares: el sonido es parte del diseño y algunos sonidos vienen de un lugar concreto del espacio.

El recorrido
Escena	Qué pasa	Qué hace el jugador
Memoria 1 · La infancia	La habitación de la abuela, a la altura de un nene de siete años. Por la ventana se ve el mar, más alto que el piso	Encuentra la canción de cuna en un libro y ordena los juguetes en la alfombra del mar siguiendo sus versos. Mueve un banquito para alcanzar la luna
Memoria 2 · La adolescencia	Pesca con el padre en un lago hasta que llega la tormenta	Pesca, corta la red trabada y huye remando por el río detrás de la luz del padre
Memoria 3 · La adultez	La madrugada antes de embarcar, en una casa que se repite y se degrada	Busca el cuarto de su hija eligiendo entre tres puertas: la buena tiene la luz del velador abajo. Le deja el barquito: "Cuidámelo hasta que vuelva"
Memoria 4 · El accidente	La cubierta del pesquero en plena tormenta	Corta con un hacha las sogas de las redes trabadas y sube el ancla, hasta que llega la ola
El despertar	La habitación del hospital	La hija le devuelve el barquito
Entre una memoria y la siguiente hay un pasaje: se camina sobre un mar negro hacia una luz, mientras se escuchan voces del hospital cada vez más claras.

No hay forma de perder: equivocarse o caerse sube la tensión, pero nunca obliga a empezar de nuevo.

Controles
Acción	Tecla
Moverse / mirar	W A S D (o flechas) y mouse
Correr	Shift
Saltar	Espacio
Interactuar (agarrar, colocar, leer, abrir, cortar, tirar la red)	E
Pelear un pez (Memoria 2)	W / S para mantener el punto en la zona verde
Remar (Memoria 2)	A remo izquierdo, D remo derecho (alternar avanza derecho), S los dos hacia atrás
Evento rápido de corte (Memorias 2 y 4)	E en el momento justo
Soltar el mouse / volver a capturarlo	Esc / clic izquierdo
Teclas de prueba
Solo para desarrollo y para mostrar el juego. No hace falta usarlas para jugar.

Tecla	Qué hace
F9	Pasa a la escena siguiente
F10	Reinicia la escena actual
8	Cámara libre
9	Deja fija la luz de un rayo
0	Saltea la etapa actual de la memoria
7	Dispara un flashback (Memoria 2)
F9 y F10 solo funcionan al correr el juego desde el editor. Las otras se apagan con la propiedad debug_keys de cada memoria.

Estructura del proyecto
scenes/
  memories/     una carpeta o escena por memoria (m1_habitacion, m2_lago, m3_casa, memory_4) y el despertar (awakening)
  passages/     los pasajes entre memorias
  player/       el jugador en primera persona
  characters/, props/, interaction/, ui/   personajes, objetos, interacción e interfaz
scripts/        la lógica (core: el flujo entre escenas; memories: una clase por memoria; world, fx, ui, puzzles...)
config/         los valores ajustables (velocidades, tiempos, luces, textos) en Resources .tres, editables desde el Inspector
assets/         modelos, texturas, sonidos, shaders y fuentes
docs/           documentación de diseño y de trabajo
tools/          herramientas y una prueba automática que recorre la Memoria 3 caminando
El orden de las escenas está en config/memory_sequence.tres. Las memorias no se conocen entre sí: cada una avisa cuando termina y el autoload GameFlow carga la siguiente con un fundido.

Documentación
CHANGELOG.md: el registro de cada decisión de diseño, con el problema que resolvía y las alternativas descartadas.
docs/ELEMENTOS_ESCENAS.md: qué hay en cada escena y qué representa.
docs/arquitectura.md: cómo se encadenan las memorias.
docs/GIT_WORKFLOW.md: cómo trabajó el equipo (etapas, ramas, reglas para no pisarse).
El Solution Design Document (SDD), que cuenta la evolución de la idea, se entrega por separado.
Equipo
Grupo 10: Matías Zuber Schachener, Theo Ledesma, Micaela Sol Acuña, Facundo Witt, Camila Arce Sayago e Ignacio García Goroj. Los roles de cada integrante están en el SDD.

Herramientas y recursos
Motor: Godot Engine 4.7, GDScript y física Jolt.
Inteligencia artificial: Claude Code (Anthropic) para la implementación en Godot y la documentación; Meshy para modelos 3D de la Memoria 4; Gemini para texturas e imágenes de referencia; ElevenLabs y Piper para voces provisorias. El diseño, las pruebas y las decisiones son del equipo.
Recursos de terceros: algunos modelos, texturas y sonidos vienen de repositorios externos. El detalle está en el SDD. El modelo de la hija en el hospital es provisorio y sirve solo para el prototipo de la cátedra.
