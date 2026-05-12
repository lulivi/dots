# swayws — Sway workspace helpers

Este directorio contiene un binario Rust que ayuda a calcular y navegar
entre espacios de trabajo en Sway. La lógica de cómputo está en la crate
biblioteca para facilitar pruebas y reutilización.

Archivos importantes
- [programs/swayws/src/main.rs](programs/swayws/src/main.rs): binario que parsea
  los subcomandos y delega la lógica en la biblioteca.
- [programs/swayws/src/lib.rs](programs/swayws/src/lib.rs): funciones reutilizables
  como `fetch_workspaces()`, `find_current_workspace_name()`,
  `compute_up_down()` y `compute_left_right()`.

Resumen de funcionamiento

- Al ejecutarse, el binario parsea un subcomando con `clap`.
- Llama a `fetch_workspaces()`, que ejecuta `swaymsg -t get_workspaces`
  y parsea el JSON devuelto.
- Determina el workspace actual con `find_current_workspace_name()` (prefiere
  el workspace enfocado; si no, usa el primero).
- Subcomandos disponibles:
  - `Current`: imprime el nombre del workspace actual.
  - `Up`: decrementa el dígito de las unidades del número del workspace
    (llama a `compute_up_down(..., down = false)`). No baja por debajo de 1.
  - `Down`: incrementa el dígito de las unidades (llama a
    `compute_up_down(..., down = true)`), con tope en 9.
  - `Left` / `Right`: saltan a la columna de decenas adyacente y
    seleccionan el workspace "base" (unidad == 1) de esa columna. Se
    implementa en `compute_left_right()` y se prefieren nombres existentes
    reportados por `swaymsg`; si no existen, se busca en definiciones de
    `variables.conf`.

Detalles relevantes
- `compute_up_down()` sólo ajusta la cifra de las unidades, manteniendo
  las decenas y superiores. Ejemplo: desde `22: Code`, `Up` -> `21: Code`,
  `Down` -> `23: Code`.
- `compute_left_right()` calcula la decena objetivo (actual ± 10) y busca
  el workspace con número `tens+1` (p. ej. 21). Si no hay coincidencia
  en `swaymsg`, intenta cargar un mapa desde `variables.conf` usando
  `load_variable_workspace_map()`.
- `load_variable_workspace_map()` respeta, en orden:
  1. la variable de entorno `SWAY_VARS` (ruta a un archivo),
  2. `./variables.conf`,
  3. `$HOME/.config/sway/config.d/variables.conf`.

Requisitos
- `swaymsg` en `PATH` (el binario lo invoca para obtener workspaces).

Compilar y ejecutar
1. En el directorio del crate:

```sh
cd programs/swayws
cargo build --release
# o en modo depuración:
cargo run -- Current
```

2. Ejecutable resultante:

```sh
target/release/swayws Current
target/release/swayws Up
target/release/swayws Left
```

Ejemplos
- Si el workspace actual es `22: Code`:
  - `swayws Up` → `21: Code`
  - `swayws Down` → `23: Code`
- Si estamos en `35: x` y existe `21: b`, entonces `swayws Left` → `21: b`.

Pruebas
- Ejecuta `cargo test` dentro de `programs/swayws` para correr los tests
  unitarios que cubren las funciones de cómputo.

Integración
- El binario imprime el nombre objetivo en `stdout`, por lo que puede usarse
  directamente desde scripts o enlazarse en la configuración de Sway.
- Las funciones públicas de la crate (`fetch_workspaces()`,
  `find_current_workspace_name()`, `compute_up_down()`, `compute_left_right()`)
  pueden importarse desde otros binarios o scripts Rust.

¿Necesitas que añada ejemplos de integración en la configuración de Sway
o un alias de shell para usar el binario fácilmente?  
