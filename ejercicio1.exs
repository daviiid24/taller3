# Ejercicio 1 - Frecuencia de palabras
# Versión 1: el archivo se lee COMPLETO en memoria con File.read/1.

# Genera dos archivos:
#   texto_normalizado.txt -> minúsculas, sin signos de puntuación, una línea por línea original
#   frecuencia.txt        -> "palabra: frecuencia", de mayor a menor frecuencia

defmodule Frecuencia do
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

    {tiempo_microsegs, resultado} = :timer.tc(fn -> procesar(entrada, carpeta) end)

    mostrar_resultado(resultado)


    tiempo_segs = tiempo_microsegs / 1_000_000
    IO.puts("Tiempo de ejecución: #{tiempo_segs} segundos")

    mostrar_archivos(resultado, carpeta)

    IO.gets(
      "\nProceso terminado. Revisa el Administrador de tareas y presiona Enter para salir..."
    )
  end

  defp pedir_rutas do
    IO.puts("=== Ejercicio 1: frecuencia de palabras (todo en memoria) ===")
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



  defp normalizar_archivo(contenido, ruta_salida) do
    texto =
      contenido
      |> separar_lineas()
      |> Enum.map(fn linea -> normalizar(linea) <> "\n" end)
      |> Enum.join()

    File.write(ruta_salida, texto)
  end


  defp separar_lineas(contenido) do
    lineas = String.split(contenido, "\n")

    if List.last(lineas) == "" do
      List.delete_at(lineas, -1)
    else
      lineas
    end
  end


  defp normalizar(linea) do
    linea
    |> String.downcase()
    |> String.replace(~r/[[:punct:]]/u, " ")
    |> String.split()
    |> Enum.join(" ")
  end



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


  defp mostrar_resultado({:ok, mensaje}), do: IO.puts(mensaje)
  defp mostrar_resultado({:error, :enoent}), do: IO.puts("Error: el archivo de entrada no existe")
  defp mostrar_resultado({:error, razon}), do: IO.puts("Error: #{razon}")


  defp pedir(mensaje, valor_por_defecto) do
    case IO.gets(mensaje) do
      :eof ->
        valor_por_defecto

      texto ->
        respuesta = texto |> String.trim() |> String.trim("\"")
        if respuesta == "", do: valor_por_defecto, else: respuesta
    end
  end

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
