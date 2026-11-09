# Beat Roulette

Una ruleta offline para salir del bloqueo creativo. Proyecto Flutter para Android 10 o superior. La edición de pruebas de GitHub Actions ofrece un APK universal para ARM de 32 bits, ARM64 y x86-64.

## Primer reto

1. En **Ruleta**, toca **GIRAR**. El resultado se guarda automáticamente.
2. Usa **Pro** para fijar un campo y volver a girar los demás. Un candado de BPM también acota los géneros compatibles.
3. Toca el botón de minutos para llevar el reto a **Tiempo**. Inicia la cuenta regresiva cuando estés listo.
4. Usa **Historial** para buscar por texto, filtrar por género, revisar notas o ver favoritos.
5. En **Reglas**, puedes crear, editar y eliminar géneros, restricciones, desafíos y condiciones. Las etiquetas hacen explícitas las restricciones de compatibilidad.
6. Pulsa **PNG** para guardar la tarjeta de 1080 × 1080 en **Imágenes / Beat Roulette**.

## Compilación

Herramientas utilizadas por el proyecto. Flutter 3.32.8, Dart 3.8.1, JDK 17 y Android SDK 35 con NDK 27.0.12077973. La primera compilación descarga dependencias. La aplicación instalada funciona offline.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release --split-per-abi --target-platform android-arm64
```

El APK se genera en `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`. Para obtener un APK universal, usa `flutter build apk --release`.

Gradle firma la compilación personal con la clave de depuración del entorno. Para distribuir actualizaciones propias, configura y conserva una clave privada estable antes de instalar esa serie de versiones. Android exige la misma firma y el mismo ID de aplicación para una actualización directa.

### APK de pruebas de GitHub

El flujo **Beat Roulette Android APK** genera un APK universal de depuración firmada y lo instala en un emulador de Android 13. El paquete `com.alemnt.beats.roulette.pruebas` aparece como **Beat Roulette Pruebas** y puede convivir con la app original. Cada instalación tiene su propia base de datos local. La compilación estándar conserva `com.alemnt.beats.roulette`.

Para reproducir la edición de pruebas, establece `ORG_GRADLE_PROJECT_beatRouletteInstallCheck=true` en el entorno y ejecuta `flutter build apk --release`.

## Arquitectura

| Capa | Archivos | Responsabilidad |
|---|---|---|
| Dominio | `lib/domain/models.dart`, `generator.dart` | Retos, perfiles, reglas, validación y contrato de persistencia. Dart puro. |
| Aplicación | `lib/application/state.dart`, `android_tools.dart` | Composición Riverpod y contrato del canal Flutter–Android. |
| Datos | `lib/data/hive_store.dart` | Implementación de `BeatStore` en Hive. |
| Presentación | `lib/presentation/` | Ruleta animada, tiempo, historial, formularios y tarjeta. |
| Plataforma | `android/app/src/main/` | Alarma local, notificación, pantalla activa y escritura en MediaStore. |
| Entrada | `lib/main.dart` | Inicializa las cajas Hive e inyecta el repositorio. |

Flujo de generación. La pantalla pasa los candados y el catálogo al generador puro, guarda el resultado por ID y actualiza Riverpod. La ruleta anima el giro y muestra el reto ya generado. La posición del puntero es decorativa y el resultado proviene del motor ponderado.

## Esquema local

| Caja o archivo | Clave | Datos |
|---|---|---|
| `history_v1` | ID de reto | Fecha UTC, género, BPM, escala, textos, IDs de reglas, límite, notas y favorito. |
| `rules_v1` | ID de regla | Tipo, texto, mínimo y máximo de BPM y etiquetas. |
| `settings_v1` | `timer` | Duración elegida y pantalla activa. |
| Preferencias Android `beat_alarm` | `deadline` | Marca de tiempo de la cuenta regresiva, para recuperar el estado al reabrir. |

Hive guarda mapas con nombres estables. Los retos conservan una copia de sus textos cuando se edita o borra una regla. Las cajas se guardan dentro del espacio privado de la aplicación y la copia de seguridad de Android está deshabilitada.

## Generación ponderada

- Cada género trae un intervalo de BPM y un centro de probabilidad. LoFi usa 60–90 BPM y un centro de 76.
- Las escalas se eligen mediante pesos por perfil para familias mayores, menores y modales. Cada raíz cromática puede aparecer.
- Las preferencias de catálogo dan más presencia a Synthwave, Retrowave, 80s Pop, Funk, Trap y Reggaetón. LoFi favorece samples vintage y los géneros retro favorecen el reto de un solo sintetizador.
- El motor filtra ternas de restricción, desafío y condición. Por ejemplo, combina un límite de tres pistas únicamente con desafíos que caben en tres pistas. Las reglas propias se validan mediante las etiquetas elegidas en el formulario. El texto libre no se interpreta semánticamente.
- Si un candado deja el catálogo sin candidatos, la app explica qué ajustar. El desafío de 20 minutos reemplaza el límite habitual del reto.

## Wireframes y navegación

| Pantalla | Orden visual de arriba abajo |
|---|---|
| Ruleta | Marca y estado offline → Rápido / Pro → rueda → botón GIRAR → candados en Pro → resultado, notas, PNG y acceso a Tiempo. |
| Tiempo | Título → contador y progreso → 15 / 30 / 45 / 60 / 120 min → iniciar o cancelar → pantalla activa y permisos. Los retos de 20 min añaden esa opción al abrirse. |
| Historial | Buscador → selector de género y favoritos → lista por fecha → hoja de detalle con notas, favorito, PNG y acceso a Tiempo. |
| Reglas | Selector de categoría → añadir → lista editable → diálogo con texto, intervalo o etiquetas. |

La barra inferior conserva las cuatro pantallas. Los controles principales usan botones de 54–58 dp de alto. La rueda dura 700 ms y respeta la preferencia del sistema para reducir movimiento. El fondo usa `#101017`, las tarjetas `#181825`, el morado `#BB96FF` y el cian `#57E8E8`. Las cifras del contador son tabulares.

## Roadmap de validación

| Hito | Resultado |
|---|---|
| 1. Motor | Perfiles ponderados, candados, reglas y pruebas deterministas. |
| 2. Flujo offline | Pantallas, Hive, favoritos, notas y persistencia después del cierre. |
| 3. Funciones Android | Aviso con sonido y vibración, pantalla activa y PNG en galería. |
| 4. APK personal | Compilar, verificar firma y manifiesto, e instalar en Android 13. |
| 5. Prueba en el Infinix | En modo avión, girar, cambiar un candado, crear una regla, revisar historial tras cerrar, exportar PNG y confirmar el aviso con pantalla apagada. |

En Android 13, activa los avisos de Beat Roulette y, para el vencimiento puntual en segundo plano, permite **Alarmas y recordatorios** desde Tiempo. Con permisos limitados, Android puede retrasar o silenciar la alerta. La alarma del sistema se pierde al reiniciar el teléfono o forzar la detención. Si vuelves a abrir la app con el plazo vencido, el contador se reconcilia con la fecha guardada.
