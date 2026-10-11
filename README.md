# Peto Assessí 🗡️

Juego tipo "asesino/killer" para grupos, 100% offline. Todo el
intercambio de información entre móviles se hace mediante códigos QR:
no hay servidor, ni internet, ni Bluetooth.

## Cómo se juega

1. El **master** crea la partida: añade jugadores y les reparte en
   persona un **PIN de 4 dígitos** por jugador (la app lo genera solo).
2. La app baraja el orden de forma aleatoria y oculta, y muestra un
   **QR cifrado** con la lista completa.
3. Cada jugador abre la app, escanea ese QR, elige su nombre en la
   lista y confirma con su PIN. La app le muestra solo **su propio
   objetivo**, nunca la cadena completa.
4. Cuando alguien "elimina" a su objetivo en persona:
   - El **cazador** pulsa "He eliminado a mi objetivo" → se abre su cámara.
   - La **víctima**, en su propio móvil, pulsa "Me han eliminado" → su
     móvil genera un nuevo QR.
   - El cazador escanea ese QR y hereda automáticamente el objetivo de
     su víctima.
5. Cuando tu nuevo objetivo eres tú mismo, has ganado — no hace falta
   lógica extra, es una lista circular clásica que se colapsa sola.

## Opciones al crear la partida

En la pantalla "Crear partida" el master decide dos cosas, que se
reparten a todos dentro del propio QR cifrado inicial:

- **Jugadores blindados con PIN / modo abierto**: con el interruptor
  activado (por defecto), cada jugador necesita su PIN de 4 dígitos
  para identificarse — evita que alguien seleccione el nombre de otra
  persona. Desactivado, cualquiera puede tocar cualquier nombre de la
  lista sin PIN: más rápido, pero basado en la confianza del grupo.
  El PIN se sigue generando internamente pase lo que pase, así que
  puedes cambiar de modo en cualquier momento mientras añades
  jugadores sin que se rompa nada.
- **Modo de juego**: una descripción de cómo se "elimina" a un
  objetivo (toque en el hombro, quitar el pañuelo/peto, palabra
  secreta, o un texto personalizado). Es puramente informativo: se
  muestra a los jugadores en la pantalla de objetivo como recordatorio,
  pero no cambia en nada el funcionamiento de la app — la norma la
  hace cumplir el propio grupo.

## Este repositorio contiene

Solo el código Dart (`lib/`) y el `pubspec.yaml`. **No incluye** las
carpetas nativas `android/` e `ios/`, porque se generan automáticamente
con el propio Flutter SDK y es mejor no llevarlas a mano.

## Puesta en marcha

Necesitas tener [Flutter](https://docs.flutter.dev/get-started/install)
instalado (con internet, para descargar el SDK y los paquetes; el
propio *juego* ya no necesita internet una vez instalado).

```bash
# 1. Crea el esqueleto nativo del proyecto
flutter create peto_assessi
cd peto_assessi

# 2. Sustituye lib/ y pubspec.yaml por los de este paquete
rm -rf lib
cp -r ruta/a/este/paquete/lib .
cp ruta/a/este/paquete/pubspec.yaml .

# 3. Descarga las dependencias
flutter pub get
```

### Permisos de cámara (obligatorio)

El proyecto que genera `flutter create` **no** pide permiso de cámara
por defecto. Hay que añadirlo a mano:

**Android** — en `android/app/src/main/AndroidManifest.xml`, dentro de
`<manifest>` y antes de `<application>`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="true" />
```

**iOS** — en `ios/Runner/Info.plist`, dentro del `<dict>` principal:

```xml
<key>NSCameraUsageDescription</key>
<string>Peto Assessí necesita la cámara para escanear los códigos QR del juego.</string>
```

Si al compilar para Android aparece un error de `minSdkVersion`, súbelo
en `android/app/build.gradle` (o `build.gradle.kts`) al valor que pida
el propio mensaje de error.

### Ejecutar

```bash
flutter run
```

Pruébalo con al menos dos móviles físicos (el escáner de cámara no
funciona bien en el emulador).

## Arquitectura

```
lib/
├── main.dart                      Arranque; retoma partida si ya existe una guardada
├── models/
│   ├── player.dart                Nombre + PIN
│   └── game_state.dart            Estado local de este móvil (vivo/eliminado/ganador)
├── services/
│   ├── crypto_service.dart        Cifrado AES-256 del contenido de los QR
│   ├── game_service.dart          Barajado circular y cálculo de objetivos
│   └── storage_service.dart       Persistencia local (shared_preferences)
└── screens/                       Una pantalla por paso del flujo descrito arriba
```

Cada móvil solo guarda **su propio** nombre, PIN y objetivo actual —
nunca la lista completa de jugadores. Eso es lo que hace innecesario
cualquier servidor: el estado global de la partida no existe en ningún
sitio, se va resolviendo objetivo a objetivo entre parejas de móviles.

## Decisiones de diseño y limitaciones conocidas

- **Cifrado del QR inicial**: usa una clave AES simétrica incrustada en
  el código de la app (la misma para todas las instalaciones). Esto
  impide leer el QR con un lector genérico o una web de descifrado —
  que era el riesgo principal — pero no protege frente a alguien que
  descompile la propia app para extraer la clave. Para una partida
  entre amigos es un nivel de protección razonable; si algún día
  quieres cerrarlo del todo, la alternativa es que el master muestre un
  QR individual y distinto a cada jugador en vez de uno compartido.
- **PIN por jugador**: evita que alguien seleccione por error (o a
  propósito) el nombre de otra persona al escanear el QR inicial.
- **Sin recuperación entre dispositivos**: si alguien pierde el móvil o
  borra la app a mitad de partida, esa parte de la cadena se rompe. Es
  una limitación aceptada por ser 100% offline y sin servidor central.
- **Disputas**: si la víctima no confirma su eliminación, no hay
  arbitraje automático — es un tema social del grupo, no técnico.
- **Tamaño del grupo**: con muchísimos jugadores el QR inicial crece
  (lleva toda la lista) y puede volverse más denso y lento de escanear.
  Para grupos de hasta 40-50 personas no debería haber problema.

## Posibles mejoras futuras

- Modo "máxima privacidad" con un QR individual por jugador.
- Pantalla de estadísticas para el master (requeriría algún canal
  adicional, ya que ahora mismo el master no tiene visión global una
  vez empezada la partida).
- Botón de "deshacer" con doble confirmación del master en caso de
  disputa.
