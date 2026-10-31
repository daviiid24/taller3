# Ejercicio 1 - Frecuencia de palabras
# Versión 1: el archivo se lee COMPLETO en memoria con File.read/1.
#
# IMPORTANTE: no se abre con doble clic (eso solo muestra el código en el Bloc de notas).
# Se ejecuta en la terminal de VS Code, ubicado en esta carpeta, con:
#   elixir ejercicio1_frecuencia.exs
# El programa pregunta los datos y muestra el resultado en pantalla.
#
# Alternativa sin preguntas:
#   elixir ejercicio1_frecuencia.exs entrada.txt         -> usa otro archivo de entrada
#   elixir ejercicio1_frecuencia.exs entrada.txt carpeta -> deja las salidas en otra carpeta
#
# Genera dos archivos:
#   texto_normalizado.txt -> minúsculas, sin signos de puntuación, una línea por línea original
#   frecuencia.txt        -> "palabra: frecuencia", de mayor a menor frecuencia

defmodule Frecuencia do
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
    IO.puts("=== Ejercicio 1: frecuencia de palabras (todo en memoria) ===")
    entrada = pedir("Archivo de entrada (Enter para usar texto.txt): ", @entrada)
    carpeta = pedir("Carpeta de salida (Enter para usar la carpeta del programa): ", @carpeta_salida)
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

    case File.read(ruta_entrada) do
      {:ok, contenido} ->
        File.mkdir_p!(carpeta)

        with :ok <- normalizar_archivo(contenido, ruta_normalizado),
             :ok <- contar_palabras(ruta_normalizado, ruta_frecuencia) do
          {:ok, "Archivos generados en #{carpeta}"}
        end

      {:error, razon} ->
        {:error, razon}
    end
  end

  # ---------- Paso 1: normalizar ----------

  defp normalizar_archivo(contenido, ruta_salida) do
    texto =
      contenido
      |> separar_lineas()
      |> Enum.map(fn linea -> normalizar(linea) <> "\n" end)
      |> Enum.join()

    File.write(ruta_salida, texto)
  end

  # Divide el texto en líneas. Si el archivo termina en "\n", el split deja una
  # cadena vacía de más al final y hay que quitarla para no inventar una línea.
  defp separar_lineas(contenido) do
    lineas = String.split(contenido, "\n")

    if List.last(lineas) == "" do
      List.delete_at(lineas, -1)
    else
      lineas
    end
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
    case File.read(ruta_normalizado) do
      {:ok, contenido} ->
        texto =
          contenido
          |> String.split()
          |> Enum.frequencies()
          |> Enum.sort_by(fn {palabra, cantidad} -> {-cantidad, palabra} end)
          |> Enum.map(fn {palabra, cantidad} -> "#{palabra}: #{cantidad}\n" end)
          |> Enum.join()

        File.write(ruta_frecuencia, texto)

      {:error, razon} ->
        {:error, razon}
    end
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

Frecuencia.main()
