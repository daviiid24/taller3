# Parte 2 - Frecuencia de palabras con STREAMS
# Versión 2 del ejercicio 1: el archivo se procesa línea por línea con File.stream!/1,
# sin cargarlo completo en memoria, tanto al normalizar como al contar.
#
# IMPORTANTE: no se abre con doble clic (eso solo muestra el código en el Bloc de notas).
# Se ejecuta en la terminal de VS Code, ubicado en esta carpeta, con:
#   elixir parte2_streams.exs
# El programa pregunta los datos y muestra el resultado en pantalla.
#
# Alternativa sin preguntas:
#   elixir parte2_streams.exs entrada.txt         -> usa otro archivo de entrada
#   elixir parte2_streams.exs entrada.txt carpeta -> deja las salidas en otra carpeta
#
# Las salidas (texto_normalizado.txt y frecuencia.txt) son idénticas a las de
# ejercicio1_frecuencia.exs. La función normalizar/1 es la misma en las dos versiones.

defmodule FrecuenciaStreams do
  @entrada Path.join(__DIR__, "texto.txt")
  @carpeta_salida __DIR__
  @limite_pantalla 20_000   # bytes; archivos más grandes no se imprimen

  def main do
    {entrada, carpeta} =
      case System.argv() do
        [entrada, carpeta] -> {entrada, carpeta}
        [entrada] -> {entrada, @carpeta_salida}
        _ -> pedir_rutas()
      end

    resultado = procesar(entrada, carpeta)
    mostrar_resultado(resultado)
    mostrar_archivos(resultado, carpeta)
  end

  # Pregunta por consola cuando el programa se ejecuta sin argumentos
  defp pedir_rutas do
    IO.puts("=== Parte 2: frecuencia de palabras con streams ===")
    entrada = pedir("Archivo de entrada (Enter para usar texto.txt): ", @entrada)
    carpeta = pedir("Carpeta de salida (Enter para usar la carpeta del programa): ", @carpeta_salida)
    {entrada, carpeta}
  end

  defp mostrar_archivos({:ok, _}, carpeta) do
    mostrar_archivo(Path.join(carpeta, "texto_normalizado.txt"))
    mostrar_archivo(Path.join(carpeta, "frecuencia.txt"))
  end

  defp mostrar_archivos(_, _), do: :ok

  # File.stream!/1 lanza excepción si el archivo no existe, así que se comprueba antes.
  # File.regular?/1 es como File.exists?/1 (el de los apuntes), pero además descarta carpetas.
  defp procesar(ruta_entrada, carpeta) do
    ruta_normalizado = Path.join(carpeta, "texto_normalizado.txt")
    ruta_frecuencia = Path.join(carpeta, "frecuencia.txt")

    if File.regular?(ruta_entrada) do
      File.mkdir_p!(carpeta)
      normalizar_archivo(ruta_entrada, ruta_normalizado)
      contar_palabras(ruta_normalizado, ruta_frecuencia)
      {:ok, "Archivos generados en #{carpeta}"}
    else
      {:error, :enoent}
    end
  end

  # ---------- Paso 1: normalizar línea por línea ----------

  # Lee una línea, la transforma y la escribe enseguida. Nunca hay más de una línea en memoria.
  defp normalizar_archivo(ruta_entrada, ruta_salida) do
    ruta_entrada
    |> File.stream!()
    |> Stream.map(fn linea -> normalizar(linea) <> "\n" end)
    |> Enum.into(File.stream!(ruta_salida, [:write]))
  end

  # Misma función que en la versión 1
  defp normalizar(linea) do
    linea
    |> String.downcase()
    |> String.replace(~r/[[:punct:]]/u, " ")
    |> String.split()
    |> Enum.join(" ")
  end

  # ---------- Paso 2: contar palabras línea por línea ----------

  # El acumulador es un mapa %{palabra => cantidad}. Crece con las palabras DISTINTAS,
  # no con el tamaño del archivo.
  defp contar_palabras(ruta_normalizado, ruta_frecuencia) do
    ruta_normalizado
    |> File.stream!()
    |> Enum.reduce(%{}, &contar_linea/2)
    |> Enum.sort_by(fn {palabra, cantidad} -> {-cantidad, palabra} end)
    |> Stream.map(fn {palabra, cantidad} -> "#{palabra}: #{cantidad}\n" end)
    |> Enum.into(File.stream!(ruta_frecuencia, [:write]))
  end

  # Suma 1 al contador de cada palabra de la línea
  defp contar_linea(linea, conteo) do
    linea
    |> String.split()
    |> Enum.reduce(conteo, fn palabra, acumulado ->
      Map.update(acumulado, palabra, 1, fn cantidad -> cantidad + 1 end)
    end)
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
