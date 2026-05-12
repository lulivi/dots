# swaykeys — Listado de atajos de Sway

`swaykeys` es un pequeño binario Rust que analiza la configuración de Sway
(`bindsym` / `bindcode`) y lista las combinaciones de teclas encontradas.
La lógica principal está en `src/main.rs` y el programa está pensado para
ser usado desde la línea de comandos o integrado en scripts de dotfiles.

Comportamiento principal

- Por defecto lee `~/.config/sway/config.d/keys.conf`, pero acepta la opción
  `--config` para indicar un archivo o un directorio.
- Si se pasa un directorio, busca `keys.conf` dentro de ese directorio.
- Ignora líneas vacías y comentarios (`#`).
- Reconoce y expande variables declaradas con `set` en la configuración.
- Detecta `mode` y bloques `bindsym { ... }` o `bindcode { ... }` y anota
  la salida con el modo correspondiente cuando aplica.

Salida

Imprime una línea por combinación encontrada con el formato:

```
<tecla> -> <comando> (ruta:lineno) [mode: nombre]
```

Ejemplo de uso

```sh
cd programs/swaykeys
# ejecutar con el config por defecto
cargo run --release --
# especificar un archivo de config
cargo run -- --config ~/.config/sway/config
# pasar un directorio que contenga keys.conf
cargo run -- --config ~/.config/sway/config.d
```

Notas de implementación

- El programa usa `shell_words` para tokenizar las líneas y `shellexpand`
  para resolver `~` en rutas.
- Variables `set` se recogen y luego se expanden en claves y comandos con
  hasta 10 pasadas para permitir expansiones anidadas.
- El parser intenta mantener contexto de `mode` y bloques para poder
  imprimir la información de modo en las líneas relevantes.

Compilar y pruebas

```sh
cd programs/swaykeys
cargo build --release
# o para pruebas manuales
cargo run -- --config path/to/config
```

Integración

- La salida en `stdout` hace que sea fácil usar `swaykeys` desde scripts
  para generar documentación de atajos, comprobar conflictos o alimentar
  herramientas de búsqueda de atajos.

¿Quieres que genere un ejemplo de alias de shell o un script que integre
la salida de `swaykeys` en un menú (rofi/dmenu)?
