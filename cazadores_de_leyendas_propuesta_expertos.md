# CAZADORES DE LEYENDAS

## Documento de concepto, diseño y arquitectura para evaluación por un grupo de expertos

**Versión:** 0.2 --- Documento de propuesta para revisión\
**Fecha:** 30 de octubre de 2026\
**Plataforma objetivo:** Roblox\
**Motor:** Roblox Studio\
**Lenguaje:** Luau\
**Público objetivo:** Niños de 8 a 12 años\
**Género:** RPG de acción, aventura, exploración y folclore mexicano\
**Estado:** Concepto inicial. Las decisiones marcadas como pendientes
deben validarse con el grupo de expertos.

------------------------------------------------------------------------

# 1. Resumen ejecutivo

**Cazadores de Leyendas** es una propuesta de videojuego RPG para Roblox
en el que los jugadores exploran regiones fantásticas inspiradas en
México, investigan criaturas del folclore, utilizan objetos y juguetes
tradicionales reinterpretados como herramientas de aventura, y
desarrollan a su personaje mediante atributos, habilidades y vestimenta
con propiedades especiales.

El juego está dirigido a niños de 8 a 12 años. Busca combinar
entretenimiento, exploración y aprendizaje cultural de forma integrada,
evitando que las actividades se sientan como lecciones escolares.

La identidad diferencial del proyecto se apoya en cuatro pilares:

1.  **Folclore mexicano:** criaturas, relatos, paisajes y leyendas de
    distintas regiones.
2.  **Objetos tradicionales como mecánicas:** honda, resortera, trompo,
    yo-yo y matraca.
3.  **Vestimenta como equipamiento RPG:** prendas inspiradas en
    indumentarias regionales que aportan atributos útiles en distintos
    entornos.
4.  **Exploración con aprendizaje:** bestiario, investigación,
    acertijos, observación, naturaleza y referencias culturales.

La propuesta aún no es un diseño cerrado. Este documento busca que
especialistas en game design, Roblox/Luau, arte 3D, narrativa, cultura
mexicana, UX infantil, seguridad y producción puedan evaluar el concepto
y ayudar a definir su alcance.

# 2. Visión del producto

Crear un mundo de aventuras donde los niños descubran leyendas
mexicanas, exploren entornos fantásticos y aprendan a observar,
investigar, resolver problemas y colaborar.

## 2.1 Propuesta de valor

Un RPG infantil donde la cultura mexicana no sea solamente decoración:
se convierta en parte de las mecánicas, la exploración, la estrategia y
la narrativa.

## 2.2 Principios de diseño

-   Exploración y curiosidad por encima de la repetición mecánica.
-   Combate no gráfico y apropiado para la edad objetivo.
-   Las criaturas no tienen que ser siempre malvadas: algunas pueden
    estar asustadas, confundidas, protegiendo su territorio o necesitar
    ayuda.
-   Recompensar la observación, la estrategia, la cooperación y la
    resolución de problemas.
-   Evitar mecánicas de presión, castigos por inactividad o sistemas
    diseñados para forzar sesiones prolongadas.
-   Permitir que el jugador disfrute y avance sin realizar compras.
-   Representar las tradiciones con respeto, investigación y contexto
    regional.

# 3. Público objetivo y experiencia

**Edad objetivo:** 8 a 12 años.

**Experiencia principal:** aventura y exploración.

**Objetivo pedagógico:** entretenimiento con aprendizaje integrado.

El juego debe tener controles sencillos, objetivos claros, interfaz
legible y dificultad progresiva. Se debe probar con usuarios
representativos de las edades objetivo, con las autorizaciones y medidas
de protección correspondientes.

## 3.1 Duración de sesión propuesta

Sesiones de referencia de 10 a 20 minutos, sin exigir conexión diaria ni
penalizar al jugador por salir.

# 4. Universo y narrativa

## 4.1 Premisa narrativa

México está representado mediante regiones fantásticas donde conviven el
mundo humano y el mundo de las leyendas. Durante generaciones,
guardianes han mantenido el equilibrio entre ambos mundos.

Una fuerza misteriosa está alterando a ciertas criaturas: algunas se han
vuelto agresivas, otras desaparecen y otras invaden pueblos o lugares
protegidos.

El jugador pertenece a una nueva generación de **Cazadores de
Leyendas**. Su misión es recorrer distintas regiones, investigar qué
está sucediendo y recuperar el equilibrio.

La premisa es provisional y debe revisarse para evitar simplificaciones
culturales o apropiaciones inadecuadas de tradiciones específicas.

## 4.2 Enfoque narrativo

No todas las criaturas deben ser enemigas. Según la criatura y la
misión, el jugador podría:

-   Rastrearla.
-   Investigar su comportamiento.
-   Descubrir qué la alteró.
-   Ahuyentarla.
-   Debilitarla o contenerla de forma fantástica.
-   Capturarla mediante una mecánica no violenta.
-   Ayudarla a recuperar el equilibrio.
-   Resolver un conflicto con los habitantes de la región.

La cacería debe entenderse como investigación y encuentro con criaturas,
no necesariamente como eliminación.

# 5. Regiones del mundo

Se propone un mundo dividido en regiones desbloqueables. No se
recomienda construir todo México en la primera versión.

## 5.1 Región 1: Pueblo de las Sombras

**Candidata para el MVP.**

-   Pueblo de arquitectura tradicional reinterpretada.
-   Plaza central y casas de personajes.
-   Cementerio tratado de manera fantástica y no terrorífica.
-   Caminos rurales y bosque cercano.
-   Primeras misiones y tutorial.
-   Criaturas de dificultad inicial.

## 5.2 Región 2: Selva Encantada

-   Selva tropical.
-   Ruinas antiguas tratadas con contexto.
-   Cenotes y cuerpos de agua.
-   Vegetación abundante.
-   Criaturas guardianas.
-   Acertijos y exploración.

## 5.3 Región 3: Sierra del Nahual

-   Montañas y bosques de pino.
-   Cuevas y senderos.
-   Clima frío y niebla.
-   Criaturas que cambian de forma.
-   Retos de rastreo y orientación.

## 5.4 Región 4: Desierto del Silencio

-   Desierto, cañones y minas.
-   Haciendas ficticias abandonadas.
-   Calor y cambios de ciclo día/noche.
-   Criaturas nocturnas.
-   Retos de preparación del equipo y exploración.

## 5.5 Región 5: Reino del Mictlán

-   Región sobrenatural inspirada en relatos sobre el inframundo mexica.
-   Arquitectura fantástica.
-   Pruebas especiales.
-   Jefes legendarios.
-   Desenlace de la historia principal.

**Nota cultural:** estas regiones son una propuesta de fantasía, no una
reconstrucción histórica ni una representación exacta de las culturas
indígenas de México. Cada región debe investigarse y documentarse de
forma independiente. El Mictlán, las tradiciones mayas, los relatos
nahuas y las leyendas regionales no deben mezclarse como si fueran una
única tradición.

# 6. Criaturas y bestiario

Las criaturas deben contar con identidad visual, comportamiento,
habilidades, región, nivel de dificultad y una estrategia de encuentro.

## 6.1 Criaturas candidatas

### Nahual

-   Figura cambiaformas inspirada en relatos sobre nahuales.
-   Puede adoptar apariencias animales o confundirse con el entorno.
-   Mecánicas posibles: rastreo, identificación de pistas y detección de
    su verdadera ubicación.
-   Candidato a jefe especial.

### Chaneque

-   Espíritu o ser travieso asociado en ciertos relatos regionales con
    espacios naturales.
-   Puede esconder objetos, crear distracciones o proteger zonas.
-   Mecánicas posibles: observación, búsqueda de pistas y resolución de
    pequeños acertijos.

### La Llorona

-   Figura legendaria presente en distintas versiones regionales.
-   Puede aparecer cerca de ríos o cuerpos de agua.
-   Mecánicas posibles: identificar sonidos, seguir pistas y resolver el
    misterio de su aparición.
-   Debe tratarse con sensibilidad y sin escenas de terror intenso para
    el público objetivo.

### Charro Negro

-   Figura legendaria asociada a caminos y apariciones nocturnas.
-   Puede utilizar sombras, desafíos o ilusiones.
-   Candidato a enemigo avanzado o encuentro narrativo.

### Aluxes

-   Seres presentes en determinadas tradiciones mayas.
-   Pueden actuar como guardianes o seres traviesos.
-   Debe investigarse su contexto cultural y evitar convertirlos en
    criaturas genéricas sin explicación.

### Criatura original

Se propone añadir una criatura inventada inspirada en fauna, paisajes o
motivos artesanales mexicanos. Esto permitirá mayor libertad creativa y
evitará atribuir características inventadas a leyendas reales.

## 6.2 Ficha estándar de criatura

Cada entrada del bestiario debe incluir:

-   Nombre y variantes regionales, si existen.
-   Región o tradición cultural documentada.
-   Fuentes de investigación.
-   Descripción para niños.
-   Diseño visual y silueta.
-   Comportamiento y hábitat dentro del juego.
-   Habilidades y nivel de dificultad.
-   Pistas que deja.
-   Estrategias para interactuar con ella.
-   Posibles desenlaces: resolver, ayudar, ahuyentar, contener o
    capturar.
-   Recompensas y entrada del bestiario.

El bestiario debe distinguir claramente entre información cultural
documentada y elementos inventados para el videojuego.

# 7. Sistema de armas y herramientas tradicionales

La propuesta es reinterpretar objetos tradicionales, juguetes y
herramientas como instrumentos fantásticos de aventura. No se busca
promover armas reales ni enseñar su fabricación o uso dañino.

Cada objeto debe tener una mecánica distinta, utilidad ambiental y
posibilidades de mejora.

## 7.1 Honda

**Rol:** ataque a distancia y precisión.

-   Lanza proyectiles fantásticos.
-   Activa mecanismos a distancia.
-   Puede servir para acertijos de puntería.
-   Mejoras: precisión, alcance y velocidad de uso.

## 7.2 Resortera

**Rol:** disparos rápidos.

-   Dispara proyectiles no letales o mágicos.
-   Puede activar objetivos.
-   Adecuada para criaturas pequeñas o móviles.
-   Mejoras: cadencia, control y efectos del proyectil.

## 7.3 Trompo

**Rol:** combate cercano y área.

-   Gira alrededor del personaje o se desplaza por una trayectoria
    fantástica.
-   Puede activar mecanismos giratorios.
-   Ataques circulares.
-   Mejoras: duración del giro, radio y control.

## 7.4 Yo-yo

**Rol:** precisión, alcance y control.

-   Se extiende y regresa.
-   Puede accionar interruptores o recuperar objetos.
-   Puede ralentizar temporalmente a una criatura.
-   Mejoras: alcance, control y velocidad.

## 7.5 Matraca

**Rol:** sonido, distracción y control.

-   Produce ondas sonoras fantásticas.
-   Puede atraer criaturas hacia una zona.
-   Puede aturdir brevemente o interrumpir habilidades.
-   Puede activar mecanismos sonoros.
-   Mejoras: radio, duración y control.

## 7.6 Principio de balance

Las herramientas no deben diferenciarse solamente por daño. Cada una
debe abrir posibilidades distintas de exploración, acertijos y
estrategia.

Ejemplo de combinación: usar la matraca para atraer a una criatura y el
yo-yo para activar un mecanismo que permita contenerla.

La pertinencia cultural, el nombre, la forma y la representación de cada
objeto deben ser revisados por especialistas.

# 8. Vestimenta tradicional como equipamiento RPG

La vestimenta tendrá dos funciones:

1.  Personalización estética del personaje.
2.  Atributos y ventajas situacionales para explorar diferentes
    regiones.

Se propone investigar prendas y elementos de distintas regiones,
evitando presentar una sola vestimenta como representativa de todo
México.

## 8.1 Conjuntos candidatos

  -----------------------------------------------------------------------
  Inspiración             Atributo de juego       Uso
                          propuesto               
  ----------------------- ----------------------- -----------------------
  Sarape de lana          Resistencia al frío     Sierra

  Sombrero de ala ancha   Protección ambiental    Desierto
                          frente al sol           

  Rebozo                  Agilidad o sigilo       Bosque

  Huaraches reforzados    Movilidad               Caminos y exploración

  Traje charro            Equilibrio y            Encuentros de combate
  reinterpretado          resistencia             

  Huipil con bordados     Afinidad sobrenatural   Regiones mágicas
  mágicos ficticios                               
  -----------------------------------------------------------------------

Los atributos son convenciones de fantasía, no propiedades reales de las
prendas. Debe evitarse asignar una prenda a una cultura o región sin
investigación suficiente.

## 8.2 Atributos de equipamiento

-   Defensa.
-   Velocidad.
-   Resistencia.
-   Sigilo.
-   Protección ambiental.
-   Afinidad sobrenatural.

No debe existir un conjunto universalmente superior. La elección del
equipo debe depender de la región, la misión y el estilo de juego.

## 8.3 Ejemplo de preparación

-   Sierra: conjunto con resistencia al frío.
-   Desierto: conjunto con protección ambiental.
-   Bosque: conjunto orientado al sigilo.
-   Reino sobrenatural: conjunto con afinidad mágica.

# 9. Sistema RPG

## 9.1 Atributos del personaje

  Atributo      Función
  ------------- ----------------------------------------
  Fuerza        Potencia de herramientas y habilidades
  Agilidad      Movimiento y evasión
  Resistencia   Salud y defensa
  Astucia       Rastreo y resolución de acertijos
  Espíritu      Habilidades sobrenaturales

Los valores y fórmulas deben balancearse mediante prototipos. Evitar que
las estadísticas conviertan los retos educativos en pruebas de pago o de
repetición excesiva.

## 9.2 Especializaciones

Se proponen tres caminos combinables:

**Rastreador** - Descubre huellas y pistas. - Identifica puntos de
interés. - Mejora la investigación.

**Guardián** - Resiste ataques. - Protege a compañeros. - Ayuda a
controlar criaturas.

**Trampero** - Utiliza objetos y mecanismos. - Prepara distracciones. -
Controla temporalmente el espacio.

El jugador no debe quedar bloqueado en una clase irreversible.

# 10. Cacería, investigación y encuentros

Flujo propuesto:

1.  Recibir una pista o rumor.
2.  Investigar huellas, sonidos y objetos.
3.  Consultar el bestiario o hablar con personajes.
4.  Descubrir hábitos y debilidades.
5.  Preparar vestimenta y herramientas.
6.  Localizar a la criatura.
7.  Resolver el encuentro mediante estrategia.
8.  Obtener una recompensa y actualizar el bestiario.

Las opciones de desenlace dependerán de la criatura: ayudarla, resolver
un conflicto, ahuyentarla, contenerla o capturarla de forma fantástica.

# 11. Aprendizaje integrado

El aprendizaje debe aparecer dentro de las mecánicas, no como una
pantalla de preguntas escolares desconectada del juego.

Áreas posibles:

-   **Cultura:** conocer el origen y las variantes de leyendas y
    objetos.
-   **Naturaleza:** identificar ecosistemas, plantas, animales y
    relaciones ambientales.
-   **Observación:** encontrar huellas, patrones y diferencias.
-   **Lógica:** resolver secuencias, mecanismos y acertijos.
-   **Orientación:** interpretar mapas y pistas.
-   **Colaboración:** coordinar tareas y compartir descubrimientos.

Los contenidos culturales deben incluir fuentes y revisión experta. No
presentar como hecho histórico una invención del juego.

# 12. Ciclo principal de juego

1.  Entrar al mundo.
2.  Elegir una misión o explorar libremente.
3.  Investigar una región.
4.  Encontrar pistas, personajes y objetos.
5.  Resolver un reto o encuentro.
6.  Obtener experiencia, materiales o coleccionables.
7.  Mejorar el personaje y su equipamiento.
8.  Desbloquear nuevas actividades o regiones.

El jugador debe poder disfrutar de una sesión corta y retomar su
progreso posteriormente.

# 13. Progresión y economía

## 13.1 Sistemas de progresión

**Experiencia** - Se obtiene al explorar, investigar y completar
misiones. - Desbloquea actividades y regiones.

**Colecciones** - Criaturas, objetos, plantas, pistas y fragmentos de
historias. - Completarlas recompensa la curiosidad.

**Equipamiento** - Mejoras de herramientas. - Prendas y accesorios. -
Elementos cosméticos y de personalización.

## 13.2 Monedas propuestas

-   Semillas de oro: moneda común.
-   Esencias: materiales especiales.
-   Fragmentos de leyenda: recompensas de misiones.

El sistema económico debe ser comprensible y no inducir compras
impulsivas.

## 13.3 Monetización

No forma parte de la primera versión. Si se incorpora más adelante,
priorizar artículos cosméticos opcionales, sin ventajas competitivas ni
presión de compra. Toda monetización debe cumplir las políticas vigentes
de Roblox y las reglas aplicables a experiencias dirigidas a menores.

# 14. Multijugador

Se propone cooperación para grupos pequeños:

-   Rastrear criaturas.
-   Resolver acertijos.
-   Enfrentar jefes.
-   Completar misiones cooperativas.
-   Descubrir lugares secretos.

El juego debe permitir completar la historia principal individualmente.
La experiencia no debe depender de encontrar jugadores desconocidos.

La modalidad exacta ---individual, cooperativa o mundo compartido---
está pendiente de decisión.

# 15. MVP: primera versión jugable

El MVP debe validar el núcleo del juego antes de producir varias
regiones.

## 15.1 Alcance propuesto

  Componente                     Cantidad inicial
  ---------------------------- ------------------
  Región                                        1
  Pueblo central                                1
  NPC principales                               3
  Criaturas                                     5
  Herramientas tradicionales                    5
  Conjuntos de vestimenta                       3
  Misiones                                     10
  Jefe final                                    1
  Minijuego de rastreo                          1
  Sistema de inventario                         1
  Sistema de niveles                            1
  Bestiario                                     1
  Sistema de guardado                           1

El MVP puede reducirse si el prototipo demuestra que cinco herramientas
y cinco criaturas exceden el alcance razonable. La prioridad es que el
ciclo de juego sea divertido y funcional.

## 15.2 Misiones candidatas

1.  Encontrar cinco objetos perdidos en el bosque.
2.  Ayudar a un personaje a resolver una secuencia lógica.
3.  Identificar plantas mediante pistas visuales.
4.  Reconstruir un puente utilizando mecanismos.
5.  Investigar el misterio del árbol antiguo.
6.  Seguir huellas de una criatura.
7.  Identificar sonidos del bosque.
8.  Recuperar objetos de una zona protegida.
9.  Resolver un acertijo cooperativo opcional.
10. Resolver el encuentro con el jefe de la región.

## 15.3 Criterios de aceptación del MVP

-   El jugador puede entrar y completar el tutorial.
-   Puede moverse e interactuar con NPC y objetos.
-   Puede aceptar, abandonar y completar misiones de forma consistente.
-   Puede recoger y consultar objetos.
-   Las herramientas tienen funciones diferenciadas.
-   Puede cambiar su vestimenta y observar sus efectos.
-   Puede obtener experiencia y subir de nivel.
-   El bestiario registra los descubrimientos.
-   El progreso persiste al salir y regresar.
-   Las mecánicas funcionan en PC y dispositivos móviles compatibles.
-   Las recompensas se validan en servidor.
-   La experiencia principal se puede completar sin compras.
-   No hay errores críticos de seguridad o pérdida de datos.

# 16. Arquitectura técnica propuesta

## 16.1 Plataforma y herramientas

-   Roblox Studio como entorno de desarrollo.
-   Luau como lenguaje.
-   Rojo para sincronizar el proyecto entre archivos y Roblox Studio.
-   Git para control de versiones.
-   GitHub para repositorio, revisiones y seguimiento.
-   Blender para modelado, edición y optimización.
-   Meshy o Tripo como herramientas opcionales para generación de
    modelos.
-   Claude Code o Cursor como asistentes de programación, sujetos a
    revisión humana.

La selección final debe considerar licencias, exportación,
compatibilidad, calidad y rendimiento de los assets.

## 16.2 Separación cliente-servidor

**Cliente** - Controles. - Cámara. - Interfaz. - Animaciones y efectos
locales. - Presentación de diálogos. - Solicitudes de interacción.

**Servidor** - Estado de misiones. - Validación de interacciones. -
Recompensas. - Inventario. - Progresión. - Guardado. - Validación de
compras futuras.

El cliente nunca será autoridad sobre monedas, recompensas, daño,
captura o progreso.

## 16.3 Servicios de Roblox a evaluar

  Servicio                 Uso
  ------------------------ ------------------------------------
  Players                  Gestión de jugadores
  ReplicatedStorage        Recursos y comunicación compartida
  ServerScriptService      Lógica de servidor
  ServerStorage            Recursos privados
  DataStoreService         Persistencia
  CollectionService        Etiquetado de objetos
  TweenService             Transiciones y animaciones
  ProximityPromptService   Interacciones
  MarketplaceService       Compras futuras
  TextChatService          Configuración de comunicación

La implementación debe verificar la documentación vigente de Roblox y
las políticas actuales antes de producción.

## 16.4 Persistencia de datos

Estructura conceptual de perfil:

-   UserId.
-   SchemaVersion.
-   PlayerLevel.
-   Experience.
-   Attributes.
-   Inventory.
-   Collections.
-   CompletedMissions.
-   Equipment.
-   HouseDecorations, si se incluye.
-   LastSavedAt.

Requisitos: - Guardado periódico. - Guardado al salir, cuando sea
posible. - Reintentos ante errores transitorios. - Validación y límites
de datos. - Migración entre versiones. - Protección contra duplicación
de recompensas. - Manejo de fallos de persistencia sin corromper el
perfil.

## 16.5 Comunicación cliente-servidor

Toda solicitud enviada por el cliente debe validarse en el servidor.

Validaciones mínimas: - El objeto o criatura existe y está activo. - El
jugador está dentro del rango permitido. - La misión corresponde al
estado actual. - El jugador cumple los requisitos. - La recompensa no
fue entregada previamente. - La frecuencia de solicitudes es
razonable. - Los valores recibidos están dentro de límites válidos.

## 16.6 Dependencias externas

No se necesita una API externa para el MVP. Conviene mantener el juego
autónomo en Roblox y minimizar la recopilación de datos personales.

# 17. Estructura de repositorio propuesta

Estructura conceptual compatible con Rojo:

``` text
cazadores-de-leyendas/
├── default.project.json
├── README.md
├── docs/
│   ├── GDD.md
│   ├── ARCHITECTURE.md
│   ├── GAMEPLAY.md
│   ├── SECURITY.md
│   ├── CULTURAL_RESEARCH.md
│   └── BACKLOG.md
├── src/
│   ├── ReplicatedStorage/
│   │   ├── Shared/
│   │   │   ├── Config/
│   │   │   ├── Types/
│   │   │   └── Utilities/
│   │   └── Remotes/
│   ├── ServerScriptService/
│   │   ├── Services/
│   │   ├── Systems/
│   │   └── Bootstrap.server.luau
│   ├── ServerStorage/
│   │   └── Assets/
│   └── StarterPlayer/
│       └── StarterPlayerScripts/
│           ├── Controllers/
│           └── UI/
├── assets/
│   ├── characters/
│   ├── creatures/
│   ├── environment/
│   ├── props/
│   ├── weapons/
│   ├── clothing/
│   ├── audio/
│   └── textures/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── manual/
└── .github/
    └── workflows/
```

La estructura es orientativa. Debe ajustarse a las convenciones reales
de Rojo, los tipos de instancia de Roblox y la estrategia de assets
elegida.

# 18. Organización de agentes de IA

Se propone un coordinador que administre tareas y agentes
especializados. Los agentes no deben trabajar sin contratos, criterios
de aceptación ni revisión.

## 18.1 Agente coordinador / productor

Responsabilidades: - Mantener alcance, backlog y prioridades. -
Descomponer tareas. - Asignar trabajo. - Identificar dependencias. -
Solicitar revisiones. - Mantener registro de decisiones. - Evitar
cambios contradictorios.

No debe aprobar automáticamente código o assets sin pruebas.

## 18.2 Agente de diseño de juego

Responsabilidades: - Mecánicas. - Progresión. - Misiones. - Balance. -
Experiencia del jugador. - Criterios de aceptación.

Entregables: - GDD. - Historias de usuario. - Tablas de balance. -
Diagramas de flujos.

## 18.3 Agente de arquitectura Roblox

Responsabilidades: - Arquitectura cliente-servidor. - Módulos y
contratos. - Seguridad. - Persistencia. - Rendimiento. - Convenciones de
código.

Entregables: - Diagramas. - Interfaces. - Decisiones técnicas. -
Revisión de seguridad.

## 18.4 Agente programador Luau

Responsabilidades: - Movimiento y controles. - Interacciones. -
Herramientas. - Misiones. - Inventario. - Equipamiento. - Bestiario. -
Progresión. - Persistencia.

Entregables: - Código Luau. - Pruebas. - Documentación técnica.

## 18.5 Agente de arte 3D

Responsabilidades: - Personajes. - Criaturas. - Herramientas. -
Vestimenta. - Escenarios. - Materiales y texturas. - Optimización de
modelos.

Herramientas posibles: - Blender. - Meshy. - Tripo.

Entregables: - Modelos compatibles con el flujo de Roblox. - Texturas. -
Rigging y animaciones, cuando corresponda. - Catálogo de assets y
licencias.

## 18.6 Agente UX/UI

Responsabilidades: - HUD. - Inventario. - Mapa. - Bestiario. -
Diálogos. - Indicadores de misión. - Accesibilidad y legibilidad.

## 18.7 Agente investigador cultural

Responsabilidades: - Investigar procedencia de leyendas. - Diferenciar
versiones regionales. - Verificar indumentaria y objetos. - Identificar
términos y representaciones sensibles. - Documentar fuentes. -
Distinguir hechos documentados de ficción.

Debe evitar inventar referencias o atribuir una tradición a una
comunidad sin evidencia.

## 18.8 Agente QA y seguridad

Responsabilidades: - Pruebas funcionales. - Pruebas de misiones. -
Pruebas de persistencia. - Pruebas de dispositivos. - Revisión de
exploits. - Pruebas de rendimiento. - Revisión de contenido y
experiencia infantil.

## 18.9 Reglas de colaboración

1.  Cada tarea tiene responsable, entradas, salidas y criterios de
    aceptación.
2.  Ningún agente cambia contratos técnicos sin aprobación del
    arquitecto.
3.  Los módulos se desarrollan en ramas o entregas separadas.
4.  Todo cambio pasa por revisión.
5.  Los assets se revisan visual y técnicamente.
6.  El QA valida antes de integrar.
7.  Las decisiones de diseño se documentan.
8.  No se aceptan entregables que sólo describan trabajo sin
    proporcionar archivos, código, pruebas o evidencia verificable.

# 19. Seguridad y diseño apropiado para menores

La seguridad debe formar parte de la arquitectura desde el inicio.

-   Evitar chat libre entre desconocidos en el MVP.
-   No solicitar nombres reales, direcciones, escuelas, teléfonos ni
    datos personales.
-   Configurar las opciones de comunicación y privacidad disponibles en
    Roblox de acuerdo con la edad y las políticas vigentes.
-   Evitar enlaces externos y comunicaciones fuera de la plataforma.
-   No permitir contenido libre generado por jugadores en la primera
    versión.
-   No incorporar IA conversacional abierta con niños.
-   No utilizar cajas de botín aleatorias ni compras aleatorias.
-   Evitar urgencia artificial, castigos por inactividad y recompensas
    diseñadas para crear presión.
-   Probar con usuarios infantiles sólo mediante procesos adecuados,
    consentimiento de responsables y medidas de protección.
-   Revisar las políticas de Roblox, privacidad y legislación aplicable
    antes de publicar.

# 20. Dirección artística

Se consideran cuatro rutas visuales, todavía sin seleccionar:

**A. Cartoon 3D** - Amigable y colorido. - Siluetas sencillas. - Lectura
visual clara. - Adecuado para rendimiento en dispositivos modestos.

**B. Fantasía misteriosa** - Ambientes mágicos y misteriosos. -
Criaturas imponentes, sin horror gráfico. - Contraste entre luz y
sombra.

**C. Folclore fantástico** - Colores intensos. - Motivos artesanales
reinterpretados. - Criaturas con diseños memorables. - Inspiración
visual mexicana investigada y contextualizada.

**D. Anime/RPG** - Personajes estilizados. - Vestimentas elaboradas. -
Habilidades especiales. - Combate visualmente espectacular, pero no
gráfico.

El equipo debe evaluar cuál permite una identidad original, una
producción sostenible y una experiencia apropiada para niños.

# 21. Plan de desarrollo preliminar

Estimación inicial para un desarrollador principal con asistencia de
agentes. Es una hipótesis de planificación, no una cotización ni
garantía.

  Fase        Trabajo                               Duración estimada
  ----------- ----------------------------------- -------------------
  1           Diseño y validación del concepto               1 semana
  2           Prototipo de movimiento y combate             2 semanas
  3           Sistema RPG y equipamiento                    2 semanas
  4           Mapa, personajes y criaturas                  3 semanas
  5           Misiones, inventario y guardado               2 semanas
  6           Pruebas y optimización                        2 semanas
  **Total**                                            **12 semanas**

La duración real dependerá del número de desarrolladores, experiencia
con Roblox, calidad y complejidad de assets, herramientas de IA,
iteraciones y alcance definitivo.

## 21.1 Hitos sugeridos

**Hito 1 --- Prototipo jugable** - Movimiento. - Cámara. - Una
herramienta funcional. - Una criatura. - Un encuentro básico.

**Hito 2 --- Vertical slice** - Fragmento del pueblo y bosque. - Un
NPC. - Una misión completa. - Una criatura con comportamiento propio. -
Una pieza de vestimenta con atributo. - Guardado básico.

**Hito 3 --- MVP completo** - Contenido definido en la sección 15. -
Persistencia y progresión. - Interfaz. - Optimización inicial.

**Hito 4 --- Pruebas y publicación** - QA. - Seguridad. - Pruebas en
dispositivos. - Revisión de contenido. - Publicación controlada.

# 22. Estrategia de expansión

Después de validar el MVP:

1.  Incorporar la Selva Encantada.
2.  Añadir nuevas criaturas y jefes.
3.  Introducir más herramientas tradicionales.
4.  Ampliar los conjuntos regionales de vestimenta.
5.  Añadir fabricación avanzada.
6.  Crear eventos estacionales.
7.  Incorporar nuevas historias y capítulos.
8.  Ampliar actividades cooperativas.
9.  Conectar el universo con cuentos, videos y otros contenidos
    editoriales, si la estrategia de propiedad intelectual lo permite.

# 23. Preguntas pendientes para el grupo de expertos

Estas decisiones no están cerradas. Se solicita al grupo evaluar
opciones, justificar recomendaciones e identificar riesgos.

## 23.1 Estilo visual

¿Qué dirección conviene más?

-   A. Cartoon 3D.
-   B. Fantasía misteriosa.
-   C. Folclore fantástico.
-   D. Anime/RPG.
-   E. Una combinación justificada.

Considerar legibilidad, rendimiento, atractivo para 8--12 años, costo de
producción y diferenciación.

## 23.2 Intensidad y naturaleza de la cacería

-   A. Combate tradicional no gráfico: derrotar criaturas.
-   B. Captura: debilitarlas y atraparlas.
-   C. Mixto: algunas se derrotan, otras se capturan y otras se ayudan.
-   D. Misterio e investigación: poco combate.

¿Qué enfoque resulta más apropiado y atractivo para el público?

## 23.3 Fidelidad al folclore

-   A. Basarse fielmente en versiones documentadas.
-   B. Inspirarse en leyendas con libertad creativa.
-   C. Combinar leyendas documentadas y criaturas originales.

¿Cómo separar correctamente los elementos históricos, regionales y
ficticios?

## 23.4 Estructura del mundo

-   A. Mundo abierto con grandes regiones.
-   B. Regiones independientes mediante portales.
-   C. Mundo semiabierto: pueblo central y regiones explorables.

Considerar límites técnicos de Roblox, rendimiento, tiempos de carga y
costo de producción.

## 23.5 Uso de herramientas tradicionales

-   A. El jugador puede usar las cinco herramientas.
-   B. Elige una especialización.
-   C. Puede llevar varias, pero equipa dos o tres simultáneamente.

¿Cómo evitar que una herramienta sea claramente superior a las demás?

## 23.6 Importancia de la vestimenta

-   A. Principalmente estadísticas y habilidades.
-   B. Principalmente personalización estética.
-   C. Ambas: apariencia, atributos y habilidades especiales.

¿Cómo evitar que las estadísticas obliguen a usar una apariencia que el
jugador no desea?

## 23.7 Multijugador

-   A. Principalmente individual.
-   B. Cooperativo de 2 a 4 jugadores.
-   C. Mundo compartido con muchos jugadores y misiones cooperativas.

Evaluar complejidad técnica, seguridad, diseño de encuentros y
persistencia.

## 23.8 Ambientación histórica

¿Qué combinación resulta más coherente?

-   A. México colonial reinterpretado.
-   B. Comunidades rurales tradicionales.
-   C. Regiones prehispánicas reinterpretadas.
-   D. Fantasía que mezcla épocas y regiones.
-   E. Una época ficticia propia con referencias investigadas.

¿Cómo evitar anacronismos involuntarios y mezclas culturales sin
contexto?

## 23.9 Preguntas técnicas adicionales

-   ¿Qué límite de jugadores por servidor conviene?
-   ¿Qué alcance debe tener el sistema de guardado?
-   ¿Cómo se gestionarán los assets generados por IA?
-   ¿Qué nivel de detalle visual es viable en móviles?
-   ¿Qué herramientas de pruebas automatizadas se utilizarán?
-   ¿Qué estrategia de ramas e integración se recomienda para agentes
    concurrentes?
-   ¿Qué tareas deben permanecer bajo aprobación humana?

# 24. Entregables solicitados al grupo de expertos

Se solicita que cada especialista entregue recomendaciones concretas, no
sólo opiniones generales.

1.  **Game Design:** revisión del ciclo principal, combate, progresión,
    dificultad y diversión.
2.  **Roblox Engineering:** arquitectura validada, riesgos técnicos,
    estructura de módulos y estrategia de persistencia.
3.  **Arte 3D:** dirección artística, guía de estilo, presupuesto de
    polígonos y pipeline de assets.
4.  **Investigación cultural:** fuentes, revisión de criaturas,
    vestimenta, herramientas y referencias regionales.
5.  **UX infantil:** navegación, controles, legibilidad, accesibilidad y
    pruebas de experiencia.
6.  **Seguridad:** riesgos de interacción, privacidad, moderación y
    políticas aplicables.
7.  **Producción:** alcance realista, dependencias, cronograma, riesgos
    y criterios para decidir si el MVP está listo.

Cada recomendación debe incluir: - Problema o decisión. - Alternativas
consideradas. - Recomendación. - Justificación. - Riesgos y
dependencias. - Impacto en el MVP. - Preguntas que aún requieren
decisión.

# 25. Criterio de éxito del proyecto

El proyecto será prometedor si logra demostrar que:

-   Explorar el mundo es divertido por sí mismo.
-   Las herramientas tradicionales tienen mecánicas únicas y útiles.
-   Cambiar de vestimenta según el entorno tiene sentido estratégico.
-   Las criaturas son memorables y respetuosas con sus referencias
    culturales.
-   El aprendizaje ocurre de forma natural.
-   El juego funciona bien en dispositivos de Roblox.
-   El progreso se guarda correctamente.
-   Los niños pueden jugar sin presión de compra ni interacción
    insegura.
-   El MVP puede mantenerse y ampliarse sin rehacer su arquitectura.

------------------------------------------------------------------------

# Solicitud al grupo

**Revisar este documento como una propuesta temprana de producto.** No
asumir que las opciones planteadas ya fueron aprobadas. Identificar
contradicciones, riesgos culturales, problemas de diseño, complejidad
técnica y oportunidades de diferenciación.

La prioridad es definir un MVP divertido, técnicamente viable, seguro y
culturalmente respetuoso antes de producir el juego completo.
