# Mide el tiempo de ejecución y la memoria máxima de uno de los scripts del taller.
#
# IMPORTANTE: se ejecuta en la terminal de VS Code (no con doble clic):
#   elixir medir.exs      -> pregunta qué versión medir y con qué archivo
# Mida UNA versión por ejecución, para que cada una arranque con la memoria limpia.
#
# Alternativa sin preguntas:
#   elixir medir.exs ejercicio1_frecuencia.exs grande.txt salida_v1
#   elixir medir.exs parte2_streams.exs        grande.txt salida_v2
#
# Tiempo:  se mide con :timer.tc/1, que devuelve {microsegundos, resultado}.
# Memoria: :erlang.memory(:total) dice cuánta memoria usa la máquina virtual (BEAM) EN ESE
#          MOMENTO, no el máximo. Por eso se crea un proceso que la consulta cada 50 ms y
#          se queda con el mayor valor visto. Es una aproximación: un pico más corto que
#          50 ms podría no verse.
#
# Para confirmar la memoria desde el sistema operativo (valor aparte, que incluye todo el proceso):
#   Linux:  /usr/bin/time -v elixir medir.exs ...   -> "Maximum resident set size (kbytes)"
#   macOS:  /usr/bin/time -l elixir medir.exs ...   -> "maximum resident set size" (en bytes)

defmodule Medidor do
  @intervalo_ms 50

  def main do
    case System.argv() do
      [script, entrada, carpeta] -> medir(script, entrada, carpeta)
      _ -> pedir_datos()
    end
  end

  # Pregunta por consola qué versión medir
  defp pedir_datos do
    IO.puts("=== Medición de tiempo y memoria ===")
    IO.puts("1) Versión 1: ejercicio1_frecuencia.exs (archivo completo en memoria)")
    IO.puts("2) Versión 2: parte2_streams.exs (streams, línea por línea)")
    opcion = pedir("Versión a medir (1 o 2, Enter para 1): ", "1")
    entrada = pedir("Archivo de entrada (Enter para grande.txt): ", "grande.txt")

    if opcion == "2" do
      medir("parte2_streams.exs", entrada, pedir("Carpeta de salida (Enter para salida_v2): ", "salida_v2"))
    else
      medir("ejercicio1_frecuencia.exs", entrada, pedir("Carpeta de salida (Enter para salida_v1): ", "salida_v1"))
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

  defp medir(script, entrada, carpeta) do
    # El script medido lee sus argumentos con System.argv(), así que se los dejamos puestos
    System.argv([entrada, carpeta])

    memoria_inicial = :erlang.memory(:total)
    muestreador = spawn(fn -> muestrear(memoria_inicial) end)

    {microsegundos, _} = :timer.tc(fn -> Code.require_file(script, __DIR__) end)

    send(muestreador, {:detener, self()})

    receive do
      {:maximo, memoria_maxima} -> mostrar(script, microsegundos, memoria_inicial, memoria_maxima)
    end
  end

  # Proceso que va guardando la mayor memoria vista. Si no llega ningún mensaje en
  # 50 ms (after), toma una nueva muestra; si llega {:detener, pid}, responde y termina.
  defp muestrear(maximo) do
    receive do
      {:detener, remitente} ->
        send(remitente, {:maximo, max(maximo, :erlang.memory(:total))})
    after
      @intervalo_ms ->
        muestrear(max(maximo, :erlang.memory(:total)))
    end
  end

  defp mostrar(script, microsegundos, memoria_inicial, memoria_maxima) do
    IO.puts("")
    IO.puts("=== Medición de #{script} ===")
    IO.puts("Tiempo de ejecución:      #{Float.round(microsegundos / 1_000_000, 2)} s")
    IO.puts("Memoria al iniciar:       #{en_megas(memoria_inicial)} MB")
    IO.puts("Memoria máxima (BEAM):    #{en_megas(memoria_maxima)} MB")
  end

  defp en_megas(bytes), do: Float.round(bytes / 1_048_576, 1)
end

Medidor.main()
