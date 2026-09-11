# Agenda

Aplicación para gestionar agendas con tareas. Cada usuario se registra, crea sus
propias agendas (por proyecto, materia o área) y dentro de cada una carga tareas
con fecha, hora y estado.

El proyecto está partido en dos: una app **Flutter** que es lo que ve el usuario,
y una **API REST en Node.js** que guarda todo en MongoDB.

---

## Índice

- [Datos básicos](#datos-básicos)
- [Stack técnico](#stack-técnico)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Cómo levantarlo](#cómo-levantarlo)
- [Configuración de red](#configuración-de-red)
- [Modelo de datos](#modelo-de-datos)
- [API](#api)
- [Arquitectura de la app](#arquitectura-de-la-app)
- [Diseño](#diseño)
- [Comandos útiles](#comandos-útiles)
- [Creadores](#creadores)

---

## Datos básicos

| | |
|---|---|
| **Nombre** | Agenda |
| **Repositorio** | https://github.com/juanpabloM-07/GitFlow-3 |
| **Tipo** | App móvil/web + API REST |
| **Base de datos** | MongoDB Atlas (base `agenda`) |
| **Idioma de la interfaz** | Español |
| **Plataformas** | Android, Web (Chrome/Edge), Windows |
| **Licencia** | ISC |

---

## Stack técnico

### Frontend — `app/`

| Paquete | Versión | Para qué |
|---|---|---|
| Flutter SDK | 3.44.7 (Dart `^3.12.2`) | Framework de la app |
| `provider` | ^6.1.5 | Manejo de estado (ChangeNotifier) |
| `http` | ^1.6.0 | Peticiones a la API |
| `shared_preferences` | ^2.5.5 | Guardar el token de sesión en el dispositivo |
| `intl` | 0.20.2 | Formato de fechas en español |
| `flutter_localizations` | SDK | Textos de Material en español |

> `intl` está fijado en `0.20.2` (sin `^`) porque `flutter_localizations` exige
> esa versión exacta. Si se sube, `flutter pub get` falla.

### Backend — `backend/`

| Paquete | Versión | Para qué |
|---|---|---|
| Node.js | 22.20.0 | Runtime |
| `express` | ^5.2.1 | Servidor HTTP y rutas |
| `mongoose` | ^9.9.5 | Modelos y conexión a MongoDB |
| `jsonwebtoken` | ^9.0.3 | Tokens de sesión (JWT) |
| `bcryptjs` | ^3.0.3 | Hash de contraseñas |
| `cors` | ^2.8.6 | Permitir peticiones desde la app web |
| `dotenv` | ^17.4.2 | Variables de entorno |
| `nodemon` | ^3.1.14 | Recarga automática en desarrollo |

---

## Estructura del proyecto

```
agenda/
├── app/                          # Aplicación Flutter
│   └── lib/
│       ├── main.dart             # Arranque + AuthGate (decide qué pantalla mostrar)
│       └── src/
│           ├── config/
│           │   ├── constants.dart    # URL de la API, estados, paleta de colores
│           │   └── theme.dart        # Tema light y colores del CRUD
│           ├── features/
│           │   ├── agenda/
│           │   │   ├── controllers/  # AgendaController, TaskController
│           │   │   ├── data/         # Modelos y servicios HTTP
│           │   │   └── presentation/
│           │   │       ├── pages/    # Lista de agendas, detalle
│           │   │       └── widgets/  # Tarjetas, formularios, chips
│           │   └── auth/
│           │       ├── controllers/  # AuthController
│           │       ├── data/         # UserModel, AuthApiServices
│           │       └── presentation/ # Login y registro
│           └── shared/
│               ├── services/         # ApiClient, TokenStorage
│               └── widgets/          # Botón, input, estados vacíos, diálogos
│
└── backend/                      # API REST
    └── src/
        ├── app.js                # Middlewares, rutas y arranque
        ├── config/db.js          # Conexión a MongoDB
        ├── models/               # Esquemas de Mongoose
        ├── controllers/          # Lógica de cada endpoint
        ├── routes/               # Definición de rutas
        └── middleware/           # Verificación del token JWT
```

La app sigue **Clean Architecture por features**: cada funcionalidad (`agenda`,
`auth`) es una carpeta independiente con sus tres capas adentro.

| Capa | Carpeta | Responsabilidad |
|---|---|---|
| Datos | `data/` | Modelos y llamadas HTTP. No sabe nada de widgets. |
| Lógica | `controllers/` | Estado de la pantalla. No sabe nada de HTTP ni de widgets. |
| Presentación | `presentation/` | Widgets. No sabe nada de HTTP. |

La regla práctica: **una capa solo puede hablar con la de abajo**. Un widget
nunca llama a `http` directamente, siempre pasa por su controller.

---

## Cómo levantarlo

### 1. Requisitos

- Node.js 22 o superior
- Flutter 3.44 o superior
- Una base de MongoDB (local o Atlas)

### 2. Backend

```bash
cd backend
npm install
npm run dev
```

Necesita un archivo `.env` en `backend/` con estas cuatro variables:

```env
PORT=3000
MONGO_URI=mongodb+srv://usuario:clave@cluster.mongodb.net/agenda
JWT_SECRET=una_clave_larga_y_secreta
NODE_ENV=development
```

> El `.env` **no se sube al repositorio** (está en `.gitignore`). Cada quien
> arma el suyo.

Si arrancó bien, la consola muestra:

```
MongoDB conectado: cluster-shard-00-02.mongodb.net
Servidor escuchando en el puerto 3000
```

Para verificarlo: `http://localhost:3000/api/health` devuelve
`{"status":"ok","db":true}`.

### 3. App

```bash
cd app
flutter pub get
flutter run
```

Para elegir plataforma: `flutter run -d chrome`, `-d windows` o `-d <emulador>`.

---

## Configuración de red

Esta es la parte que más problemas da, así que conviene entenderla.

El backend corre en `localhost:3000` **de la PC**. Pero "localhost" significa
cosas distintas según dónde corra la app:

| Dónde corre la app | Host que tiene que usar | Por qué |
|---|---|---|
| Chrome / Edge / Windows | `localhost` | Es la misma máquina |
| Emulador de Android | `10.0.2.2` | El emulador es una máquina virtual; `localhost` es él mismo, no la PC |
| Celular físico | IP de la PC en la wifi (`192.168.x.x`) | Son dos equipos distintos en la red |

Por eso `ApiConfig` en `app/lib/src/config/constants.dart` **elige el host solo**:

```dart
static String get host {
  if (manualHost != null) return manualHost!;
  if (kIsWeb) return 'localhost';
  if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2';

  return 'localhost';
}
```

**Para probar en un celular físico**, poner la IP de la PC en `manualHost`:

```dart
static const String? manualHost = '192.168.0.10';
```

(Se consigue con `ipconfig` en Windows. Además hay que permitir el puerto 3000
en el firewall, y el celular tiene que estar en la misma red wifi.)

### Si la app dice "El servidor no respondió a tiempo"

Significa que nadie contestó, no que haya fallado. En orden:

1. ¿El backend está corriendo? → abrir `http://localhost:3000/api/health`
2. ¿El host es el correcto para la plataforma? → ver la tabla de arriba
3. ¿La petición llega al servidor? → el backend loguea **cada** petición con su
   duración. Si ahí no aparece nada, el problema es de red (IP o firewall), no
   del código.

```
POST /api/auth/login -> 401 (101ms)
POST /api/tasks -> 201 (310ms)
```

---

## Modelo de datos

Tres colecciones en la base `agenda`:

```
users  1 ──── N  agendas  1 ──── N  tasks
```

### `users`

| Campo | Tipo | Notas |
|---|---|---|
| `name` | String | Obligatorio |
| `email` | String | Obligatorio, único, se guarda en minúsculas |
| `password` | String | Hasheada con bcrypt, nunca se devuelve en las respuestas |
| `createdAt` / `updatedAt` | Date | Automáticos |

### `agendas`

| Campo | Tipo | Notas |
|---|---|---|
| `title` | String | Obligatorio |
| `description` | String | Opcional |
| `color` | String | Hex, ej. `#2563EB`. Identificador visual |
| `user` | ObjectId → User | Dueño de la agenda |

### `tasks`

| Campo | Tipo | Notas |
|---|---|---|
| `title` | String | Obligatorio |
| `description` | String | Opcional |
| `date` | Date | Día de la tarea |
| `time` | String | Hora en formato `"HH:mm"` |
| `status` | String | `pending`, `in_progress`, `completed`, `cancelled` |
| `agenda` | ObjectId → Agenda | A qué agenda pertenece |
| `user` | ObjectId → User | Dueño, para filtrar sin hacer join |

**Por qué `tasks` guarda también `user`:** permite listar todas las tareas de una
persona con una sola consulta, sin tener que buscar primero sus agendas.

**Borrado en cascada:** al eliminar una agenda se borran todas sus tareas. Una
tarea sin agenda no tendría sentido.

---

## API

Base: `http://<host>:3000/api`

Todas las respuestas son JSON. Los errores tienen la forma
`{ "message": "texto del error" }`.

### Autenticación

| Método | Ruta | Token | Descripción |
|---|---|---|---|
| `POST` | `/auth/register` | No | Crea la cuenta y devuelve token + usuario |
| `POST` | `/auth/login` | No | Valida credenciales y devuelve token + usuario |
| `GET` | `/auth/me` | Sí | Devuelve el usuario del token |

### Agendas

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/agendas` | Lista las agendas del usuario, con `taskCount` y `completedCount` |
| `GET` | `/agendas/:id` | Una agenda |
| `POST` | `/agendas` | Crea |
| `PUT` | `/agendas/:id` | Edita |
| `DELETE` | `/agendas/:id` | Elimina (borra sus tareas también) |

### Tareas

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/tasks` | Lista tareas. Filtros: `?agenda=<id>` y `?status=<estado>` |
| `GET` | `/tasks/:id` | Una tarea |
| `POST` | `/tasks` | Crea |
| `PUT` | `/tasks/:id` | Edita |
| `DELETE` | `/tasks/:id` | Elimina |

### Otros

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/health` | Estado del servidor y de la base |

### Cómo funciona el token

1. `register` o `login` devuelven un JWT que dura **7 días**.
2. La app lo guarda con `shared_preferences`.
3. Cada petición siguiente lo manda en el header:

```
Authorization: Bearer <token>
```

4. El middleware `protect` lo verifica y deja el usuario en `req.user`.
5. **Todas** las consultas filtran por `req.user._id`, así que nadie puede ver
   ni tocar datos de otra persona aunque adivine un ID.
6. Si el token vence, el backend responde `401` y la app vuelve al login sola.

---

## Arquitectura de la app

### El flujo de una acción, de punta a punta

Ejemplo: el usuario toca "Crear tarea".

```
TaskFormSheet (widget)
      │  llama a
      ▼
TaskController.create(task)          ← prende el spinner, avisa a la UI
      │  llama a
      ▼
TaskApiServices.create(task)         ← arma el JSON
      │  llama a
      ▼
ApiClient.post('/tasks', body)       ← agrega el token, la URL y el timeout
      │  HTTP
      ▼
   Backend
      │
      ▼
TaskController guarda el resultado y llama a notifyListeners()
      │
      ▼
Flutter redibuja las pantallas que estaban escuchando
```

### Piezas clave

**`AuthGate`** (en `main.dart`) — mira el estado de la sesión y decide qué
pantalla mostrar. Es el único lugar donde se define eso:

| Estado | Pantalla |
|---|---|
| `unknown` | Splash (mientras revisa si hay sesión guardada) |
| `authenticated` | Lista de agendas |
| `unauthenticated` | Login |

**`ApiClient`** — centraliza todo lo repetitivo de hablar con el backend: arma la
URL, agrega el header `Authorization`, corta si el servidor tarda más de 10
segundos y convierte cualquier falla en un `ApiException` con mensaje en
castellano. Es una única instancia compartida (`ApiClient.shared`) para
reaprovechar la conexión entre peticiones.

**`TokenStorage`** — guarda el token en disco y además lo mantiene en memoria,
así no hay que leer del disco en cada petición.

**Los controllers** — extienden `ChangeNotifier`. Guardan los datos y el estado
(`isLoading`, `isSaving`, `errorMessage`) y llaman a `notifyListeners()` cuando
algo cambia. Los widgets leen con `context.watch<T>()` y ejecutan acciones con
`context.read<T>()`.

**Filtros y búsqueda en memoria** — buscar una agenda o filtrar tareas por estado
no va al servidor, se hace sobre la lista ya cargada. Son pocos datos y la
respuesta es instantánea.

**Sincronización de contadores** — cuando se crea o completa una tarea, la
pantalla de detalle le avisa al `AgendaController` los totales nuevos
(`syncCounts`) en lugar de recargar toda la lista de agendas. Es una petición
menos.

### Decisiones del backend que importan

- **Conecta a Mongo antes de escuchar.** Así el servidor nunca acepta peticiones
  que no va a poder responder.
- **`bufferCommands: false`.** Si la base está caída, la consulta falla al
  instante en lugar de quedar encolada esperando.
- **`serverSelectionTimeoutMS: 8000`.** Por defecto Mongoose espera 30 segundos,
  demasiado para una app.
- **Middleware de 503.** Si la base no está conectada, corta con un mensaje
  claro.
- **Escucha en `0.0.0.0`.** Permite que un celular de la misma wifi se conecte.

---

## Diseño

Tema claro, definido en `app/lib/src/config/theme.dart`.

### Colores base

| Uso | Color |
|---|---|
| Fondo | `#F8FAFC` |
| Superficies (tarjetas, inputs) | `#FFFFFF` |
| Bordes | `#E2E8F0` |
| Primario | `#2563EB` |
| Texto principal | `#0F172A` |
| Texto secundario | `#475569` |

### Colores por acción del CRUD

La idea es que la intención se lea de un vistazo, sin tener que leer el texto:

| Acción | Color |
|---|---|
| Crear | Verde `#16A34A` |
| Editar | Ámbar `#F59E0B` |
| Eliminar | Rojo `#DC2626` |
| Consultar | Celeste `#0EA5E9` |

### Estados de tarea

| Estado | Etiqueta | Color |
|---|---|---|
| `pending` | Pendiente | Gris `#64748B` |
| `in_progress` | En progreso | Ámbar `#F59E0B` |
| `completed` | Completada | Verde `#16A34A` |
| `cancelled` | Cancelada | Rojo `#DC2626` |

Las tareas cuya fecha y hora ya pasaron y siguen sin completarse se marcan como
**Vencida** en rojo.

---

## Comandos útiles

### App

```bash
flutter pub get              # Instalar dependencias
flutter run                  # Ejecutar
flutter run -d chrome        # Ejecutar en el navegador
flutter analyze              # Revisar el código
flutter test                 # Correr los tests
flutter build apk            # Compilar para Android
flutter build web            # Compilar para web
flutter devices              # Ver dispositivos disponibles
flutter emulators            # Ver emuladores de Android
```

### Backend

```bash
npm run dev                  # Ejecutar con recarga automática
npm start                    # Ejecutar normal
```

---

## Convenciones de código

- **Sin APIs deprecadas.** Se usan las actuales: `Color.withValues` (no
  `withOpacity`), `CardThemeData` (no `CardTheme`), `WidgetStateProperty` (no
  `MaterialStateProperty`).
- **Comentarios por bloques.** Cada archivo está dividido en secciones con un
  encabezado, y los comentarios explican el *por qué*, no el *qué*.
- **Nombres de archivo.** `*_model.dart` para modelos, `*_api_services.dart`
  para servicios HTTP, `*_controller.dart` para controllers.
- **`flutter analyze` sin warnings** antes de commitear.

---

## Creadores

| | |
|---|---|
| **Jucvyu** | [@Jucvyu](https://github.com/Jucvyu) |
| **juanpabloM-07** | [@juanpabloM-07](https://github.com/juanpabloM-07) |
