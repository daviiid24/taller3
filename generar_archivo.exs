# Genera un archivo de texto grande para el experimento de la Parte 2.
#
# IMPORTANTE: se ejecuta en la terminal de VS Code (no con doble clic):
#   elixir generar_archivo.exs      -> pregunta el tamaño y el nombre del archivo
#
# Alternativa sin preguntas:
#   elixir generar_archivo.exs 100             -> ~100 MB en grande.txt (para pruebas rápidas)
#   elixir generar_archivo.exs 1100 otro.txt   -> tamaño en MB y nombre del archivo
#
# El texto mezcla palabras de un vocabulario pequeño con tildes, eñes, mayúsculas, signos
# de apertura (¿ ¡), puntuación, espacios repetidos, tabuladores y líneas vacías, para que
# las dos versiones del programa tengan que resolver los mismos casos que en el ejercicio 1.
#
# Para que sea rápido, se crean pocos bloques distintos de líneas y se escriben repetidos
# (Stream.cycle/1) hasta alcanzar el tamaño pedido. Cada bloque se escribe de una sola vez.

defmodule Generador do
  @ruta_por_defecto Path.join(__DIR__, "grande.txt")
  @megas_por_defecto 1100

  @bloques_distintos 20
  @lineas_por_bloque 5000

  @palabras [
    "hola", "José", "niño", "PIÑA", "árbol", "Árboles", "cómo", "está", "más",
    "Armenia", "Quindío", "Colombia", "Elixir", "programación", "archivo", "stream",
    "memoria", "texto", "línea", "palabra", "el", "la", "los", "y", "en", "de",
    "otra", "vez", "llegó", "comió", "señor", "canción", "pingüino", "co-autor",
    "29/10/2026", "2026", "ÁRBOL", "NIÑO"
  ]
  @antes ["", "", "", "¿", "¡"]
  @despues ["", "", "", "", ",", ".", "!", "?", "...", ";", ":"]
  @separadores [" ", " ", " ", "  ", "\t"]

  def main do
    {megas, ruta} = leer_argumentos(System.argv())

    bloques = for _ <- 1..@bloques_distintos, do: crear_bloque()

    tamano_promedio =
      bloques
      |> Enum.map(&byte_size/1)
      |> Enum.sum()
      |> div(length(bloques))

    cantidad_de_bloques = div(megas * 1_000_000, tamano_promedio) + 1

    IO.puts("Generando aproximadamente #{megas} MB en #{ruta} ...")

    {microsegundos, _} =
      :timer.tc(fn ->
        bloques
        |> Stream.cycle()
        |> Stream.take(cantidad_de_bloques)
        |> Enum.into(File.stream!(ruta, [:write]))
      end)

    tamano_final = File.stat!(ruta).size
    IO.puts("Listo: #{Float.round(tamano_final / 1_000_000, 1)} MB en #{Float.round(microsegundos / 1_000_000, 1)} s")
  end

  defp leer_argumentos([megas, ruta]), do: {String.to_integer(megas), ruta}
  defp leer_argumentos([megas]), do: {String.to_integer(megas), @ruta_por_defecto}
  defp leer_argumentos(_), do: pedir_datos()

  # Pregunta por consola; Enter acepta el valor por defecto
  defp pedir_datos do
    IO.puts("=== Generador de archivo de texto grande ===")
    megas = pedir("Tamaño en MB (Enter para #{@megas_por_defecto}, 100 sirve para pruebas rápidas): ", "#{@megas_por_defecto}")
    ruta = pedir("Nombre del archivo (Enter para grande.txt): ", @ruta_por_defecto)

    case Integer.parse(megas) do
      {numero, ""} when numero > 0 -> {numero, ruta}
      _ ->
        IO.puts("Tamaño no válido, se usarán #{@megas_por_defecto} MB")
        {@megas_por_defecto, ruta}
    end
  end

  defp pedir(mensaje, valor_por_defecto) do
    case IO.gets(mensaje) do
      :eof ->
        valor_por_defecto

      texto ->
        respuesta = texto |> String.trim() |> String.trim("\"")
        if respuesta == "", do: valor_por_defecto, else: respuesta
    end
  end

  # Un bloque es un texto de varias líneas, listo para escribirse
  defp crear_bloque do
    1..@lineas_por_bloque
    |> Enum.map(fn _ -> crear_linea() <> "\n" end)
    |> Enum.join()
  end

  # Una de cada 20 líneas queda vacía
  defp crear_linea do
    if Enum.random(1..20) == 1 do
      ""
    else
      cantidad_de_palabras = Enum.random(1..12)

      1..cantidad_de_palabras
      |> Enum.map(fn _ -> crear_palabra() <> Enum.random(@separadores) end)
      |> Enum.join()
    end
  end

  defp crear_palabra do
    Enum.random(@antes) <> Enum.random(@palabras) <> Enum.random(@despues)
  end
end

Generador.main()
