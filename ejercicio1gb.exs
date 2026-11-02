# Versión 2 Procesamiento línea por línea con Streams (sin cargar en memoria).

defmodule FrecuenciaStreams do
  @entrada Path.join(__DIR__, "texto.txt")
  @carpeta_salida __DIR__
  # bytes; archivos más grandes no se imprimen
  @limite_pantalla 20_000

  def main do
    {entrada, carpeta} =
      case System.argv() do
        [entrada, carpeta] -> {entrada, carpeta}
        [entrada] -> {entrada, @carpeta_salida}
        _ -> pedir_rutas()
      end

    # Se usa :timer.tc/1 para medir el tiempo de ejecución de la función procesar/2
    {tiempo_microsegs, resultado} = :timer.tc(fn -> procesar(entrada, carpeta) end)

    mostrar_resultado(resultado)

    # Mostrar el tiempo medido en segundos
    tiempo_segs = tiempo_microsegs / 1_000_000
    IO.puts("Tiempo de ejecución: #{tiempo_segs} segundos")

    mostrar_archivos(resultado, carpeta)

    IO.gets(
      "\nProceso terminado. Revisa el Administrador de tareas y presiona Enter para salir..."
    )
  end

  # Pregunta por consola cuando el programa se ejecuta sin argumentos
  defp pedir_rutas do
    IO.puts("=== Ejercicio 1: frecuencia de palabras (Streams) ===")
    entrada = pedir("Archivo de entrada (Enter para usar texto.txt): ", @entrada)

    carpeta =
      pedir("Carpeta de salida (Enter para usar la carpeta del programa): ", @carpeta_salida)

    {entrada, carpeta}
  end

  defp mostrar_archivos({:ok, _}, carpeta) do
    mostrar_archivo(Path.join(carpeta, "texto_normalizado.txt"))
    mostrar_archivo(Path.join(carpeta, "frecuencia.txt"))
  end

  defp mostrar_archivos(_, _), do: :ok

  # Lee el texto, genera el archivo normalizado y luego el de frecuencias
  defp procesar(ruta_entrada, carpeta) do
    ruta_normalizado = Path.join(carpeta, "texto_normalizado.txt")
    ruta_frecuencia = Path.join(carpeta, "frecuencia.txt")

    # En lugar de leer el archivo con File.read, solo comprobamos si existe con File.stat
    case File.stat(ruta_entrada) do
      {:ok, _} ->
        File.mkdir_p!(carpeta)

        # normalizar_archivo ahora recibe la ruta en vez del contenido en memoria
        with :ok <- normalizar_archivo(ruta_entrada, ruta_normalizado),
             :ok <- contar_palabras(ruta_normalizado, ruta_frecuencia) do
          {:ok, "Archivos generados en #{carpeta}"}
        end

      {:error, razon} ->
        {:error, razon}
    end
  end

  # ---------- Paso 1: normalizar ----------

  defp normalizar_archivo(ruta_entrada, ruta_salida) do
    ruta_entrada
    |> File.stream!(read_ahead: 100_000)
    |> Stream.map(fn linea -> normalizar(linea) <> "\n" end)
    |> Stream.into(File.stream!(ruta_salida, [:delayed_write]))
    |> Stream.run()

    :ok
  end

  # Minúsculas, signos de puntuación -> espacio, y espacios/tabuladores repetidos -> un solo espacio
  defp normalizar(linea) do
    linea
    |> String.downcase()
    |> String.replace(~r/[[:punct:]]/u, " ")
    |> String.split()
    |> Enum.join(" ")
  end

  # ---------- Paso 2: contar palabras (a partir del archivo normalizado) ----------

  defp contar_palabras(ruta_normalizado, ruta_frecuencia) do
    texto =
      ruta_normalizado
      |> File.stream!(read_ahead: 100_000)
      |> Enum.reduce(%{}, fn linea, acc ->
        linea
        |> String.split()
        |> Enum.reduce(acc, fn palabra, acc_interno ->
          Map.update(acc_interno, palabra, 1, &(&1 + 1))
        end)
      end)
      |> Enum.sort_by(fn {palabra, cantidad} -> {-cantidad, palabra} end)
      |> Enum.map(fn {palabra, cantidad} -> "#{palabra}: #{cantidad}\n" end)
      |> Enum.join()

    File.write(ruta_frecuencia, texto)
  end

  # ---------- Mostrar resultado ----------

  defp mostrar_resultado({:ok, mensaje}), do: IO.puts(mensaje)
  defp mostrar_resultado({:error, :enoent}), do: IO.puts("Error: el archivo de entrada no existe")
  defp mostrar_resultado({:error, razon}), do: IO.puts("Error: #{razon}")

  # ---------- Entrada por consola y salida por pantalla ----------

  # Muestra el mensaje, lee lo que escribe el usuario y, si solo presiona Enter,
  # devuelve el valor por defecto. También quita comillas por si se arrastró la ruta.
  defp pedir(mensaje, valor_por_defecto) do
    case IO.gets(mensaje) do
      :eof ->
        valor_por_defecto

      texto ->
        respuesta = texto |> String.trim() |> String.trim("\"")
        if respuesta == "", do: valor_por_defecto, else: respuesta
    end
  end

  # Imprime el contenido de un archivo, salvo que sea demasiado grande para la pantalla
  defp mostrar_archivo(ruta) do
    if File.regular?(ruta) do
      if File.stat!(ruta).size <= @limite_pantalla do
        IO.puts("\n--- #{Path.basename(ruta)} ---")
        IO.write(File.read!(ruta))
      else
        IO.puts("\n--- #{Path.basename(ruta)} es muy grande para mostrarlo en pantalla ---")
      end
    end
  end
end

FrecuenciaStreams.main()
