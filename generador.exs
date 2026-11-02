ruta = "archivo_1gb.txt"
linea = "Este es un texto de prueba para la clase de programacion. Evaluando el rendimiento de elixir.\n"
# La línea tiene aprox 94 bytes. 1 GB = 1073741824 bytes.
# 1073741824 / 94 = ~11,422,785 líneas.
total_lineas = 11_500_000

IO.puts("Generando archivo de 1 GB. Esto tomará unos segundos...")

archivo = File.open!(ruta, [:write])
Enum.each(1..total_lineas, fn _ ->
  IO.write(archivo, linea)
end)
File.close(archivo)

IO.puts("Archivo #{ruta} generado con éxito.")
