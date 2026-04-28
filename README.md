# Gastos App 📱

Aplicación móvil Android para control de gastos e ingresos personales. Se conecta a un backend Flask que sincroniza los datos con Google Sheets, permitiendo gestionar las finanzas tanto desde el móvil como desde la hoja de cálculo.

---

## Características

- **Dashboard** con gráficos de ingresos vs gastos por mes y distribución por categorías
- **Gestión de gastos e ingresos** con filtros por año, mes y categoría
- **Presupuesto mensual** por categoría con barras de progreso (verde / naranja / rojo)
- **Categorías** separadas por tipo (gasto / ingreso), con alta y baja
- Tema claro y oscuro automático según el sistema
- Pull-to-refresh en todas las pantallas

---

## Requisitos

- Android 5.0 (API 21) o superior
- Estar conectado a la **misma red WiFi** que el servidor
- El backend Flask corriendo en `192.168.50.25:5000`

---

## Stack tecnológico

| Capa | Tecnología |
|------|-----------|
| Framework | Flutter 3.x (Dart) |
| HTTP | `http ^1.2.1` |
| Gráficos | `fl_chart ^0.68.0` |
| Formato de fechas y moneda | `intl ^0.19.0` |
| Backend | Python + Flask (repositorio separado) |
| Datos | Google Sheets (via gspread) |

---

## Estructura del proyecto

```
lib/
├── main.dart                      # Entrada de la app y navegación principal
├── config/
│   └── api_config.dart            # URL base del servidor Flask
├── models/
│   ├── expense.dart               # Modelo de gasto
│   ├── income.dart                # Modelo de ingreso
│   ├── category.dart              # Modelo de categoría
│   └── budget.dart                # Modelos de presupuesto y dashboard
├── services/
│   └── api_service.dart           # Cliente HTTP con todos los endpoints
├── screens/
│   ├── dashboard_screen.dart      # Pantalla principal con gráficos
│   ├── expenses_screen.dart       # Lista y CRUD de gastos
│   ├── income_screen.dart         # Lista y CRUD de ingresos
│   ├── budget_screen.dart         # Presupuesto por categoría
│   └── categories_screen.dart     # Gestión de categorías
└── widgets/
    ├── summary_card.dart           # Tarjeta de resumen (ingresos/gastos/ahorro)
    ├── error_view.dart             # Vista de error con botón reintentar
    └── amount_field.dart           # Campo de texto para importes
```

---

## Instalación y uso

### 1. Clonar el repositorio

```bash
git clone https://github.com/domoticasalve/gastos-app.git
cd gastos-app
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar la IP del servidor

Edita [`lib/config/api_config.dart`](lib/config/api_config.dart) y ajusta la IP si es necesario:

```dart
static const String baseUrl = 'http://192.168.50.25:5000';
```

### 4. Ejecutar en modo desarrollo

Conecta un dispositivo Android o lanza un emulador y ejecuta:

```bash
flutter run
```

### 5. Generar APK de producción

```bash
flutter build apk --release
```

El APK se genera en:
```
build/app/outputs/flutter-apk/app-release.apk
```

Cópialo al móvil e instálalo (necesitarás tener activada la opción *Instalar apps de fuentes desconocidas* en Ajustes).

---

## API del backend

La app consume los siguientes endpoints del servidor Flask:

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/dashboard` | Totales, ahorro y datos para gráficos |
| `GET` | `/api/expenses` | Lista de gastos (filtros: year, month, category) |
| `POST` | `/api/expenses` | Añadir gasto |
| `PUT` | `/api/expenses` | Editar gasto |
| `DELETE` | `/api/expenses` | Eliminar gasto |
| `GET` | `/api/income` | Lista de ingresos |
| `POST` | `/api/income` | Añadir ingreso |
| `PUT` | `/api/income` | Editar ingreso |
| `DELETE` | `/api/income` | Eliminar ingreso |
| `GET` | `/api/categories` | Lista de categorías |
| `POST` | `/api/categories` | Añadir categoría |
| `DELETE` | `/api/categories` | Eliminar categoría |
| `GET` | `/api/budget` | Presupuesto por categoría |
| `POST` | `/api/budget` | Guardar objetivo de presupuesto |
| `GET` | `/api/yearly` | Resumen anual |

---

## Backend

El servidor Flask con la lógica de Google Sheets se encuentra en un repositorio separado. Para desplegarlo en la máquina virtual, consulta su `README.md` y la carpeta `deploy/`.

---

## Licencia

Uso personal.
