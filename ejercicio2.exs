# Ejercicio 2 Procesamiento de un CSV de productos

# Genera:
#   inventario.txt -> valor total, producto más caro, más barato y lista ordenada por valor
#   errores.txt    -> una línea por cada registro inválido, con número de línea y motivo

defmodule Inventario do
  @entrada Path.join(__DIR__, "productos.csv")
  @limite_pantalla 20_000   # bytes; archivos más grandes no se imprimen

  def main do
    {ruta_csv, carpeta} =
      case System.argv() do
        [ruta, carpeta] -> {ruta, carpeta}
        [ruta] -> {ruta, __DIR__}
        _ -> pedir_datos()
      end

    resultado = procesar(ruta_csv, carpeta)
    mostrar_resultado(resultado)
    mostrar_archivos(resultado, carpeta)
  end

  defp mostrar_archivos({:ok, _}, carpeta) do
    mostrar_archivo(Path.join(carpeta, "inventario.txt"))
    mostrar_archivo(Path.join(carpeta, "errores.txt"))
  end

  defp mostrar_archivos(_, _), do: :ok

  defp pedir_datos do
    IO.puts("=== Ejercicio 2: inventario de productos ===")
    ruta = pedir("Archivo CSV (Enter para usar productos.csv): ", @entrada)

    carpeta =
      pedir("Carpeta de salida (Enter para usar la carpeta del programa, o escriba por ejemplo salida_prueba): ", __DIR__)

    {ruta, carpeta}
  end


  defp procesar(ruta_csv, carpeta) do
    if File.regular?(ruta_csv) do
      {productos, errores} = leer_productos(ruta_csv)

      File.mkdir_p!(carpeta)
      guardar_errores(errores, Path.join(carpeta, "errores.txt"))

      if productos == [] do
        {:error, "el archivo no contiene productos válidos (líneas con error: #{length(errores)})"}
      else
        File.write!(Path.join(carpeta, "inventario.txt"), generar_reporte(productos))

        {:ok,
         "Productos válidos: #{length(productos)}. Líneas con error: #{length(errores)}. " <>
           "Archivos generados en #{carpeta}"}
      end
    else
      {:error, "el archivo #{ruta_csv} no existe o no es un archivo"}
    end
  end


  defp leer_productos(ruta) do
    resultados =
      ruta
      |> File.stream!()
      |> Stream.with_index(1)
      |> Stream.drop(1)
      |> Enum.map(fn {linea, numero} -> {numero, convertir_linea(linea)} end)

    productos = for {_numero, {:ok, producto}} <- resultados, do: producto
    errores = for {numero, {:error, motivo}} <- resultados, do: {numero, motivo}

    {productos, errores}
  end


  defp convertir_linea(linea) do
    campos = separar_campos(String.trim(linea))

    with {:ok, nombre, texto_precio, texto_cantidad} <- verificar_campos(campos),
         {:ok, nombre} <- validar_nombre(nombre),
         {:ok, precio} <- validar_precio(texto_precio),
         {:ok, cantidad} <- validar_cantidad(texto_cantidad) do
      {:ok, %{nombre: nombre, precio: precio, cantidad: cantidad}}
    end
  end

  defp verificar_campos([""]), do: {:error, "línea vacía"}
  defp verificar_campos([nombre, precio, cantidad]), do: {:ok, nombre, precio, cantidad}

  defp verificar_campos(campos) do
    {:error, "se esperaban 3 campos y hay #{length(campos)}"}
  end

  defp validar_nombre(""), do: {:error, "el nombre está vacío"}
  defp validar_nombre(nombre), do: {:ok, nombre}

  defp validar_precio(texto) do
    case Float.parse(texto) do
      {precio, ""} when precio >= 0 -> {:ok, precio}
      {_precio, ""} -> {:error, "el precio es negativo (#{texto})"}
      _ -> {:error, "el precio no es un número (#{inspect(texto)})"}
    end
  end

  defp validar_cantidad(texto) do
    case Integer.parse(texto) do
      {cantidad, ""} when cantidad >= 0 -> {:ok, cantidad}
      {_cantidad, ""} -> {:error, "la cantidad es negativa (#{texto})"}
      _ -> {:error, "la cantidad no es un número entero (#{inspect(texto)})"}
    end
  end


  defp separar_campos(linea) do
    linea
    |> String.graphemes()
    |> separar([], "", false)
    |> Enum.map(&String.trim/1)
  end

  defp separar([], campos, actual, _dentro), do: Enum.reverse([actual | campos])

  defp separar(["\"" | resto], campos, actual, dentro) do
    separar(resto, campos, actual, not dentro)
  end


  defp separar(["," | resto], campos, actual, false) do
    separar(resto, [actual | campos], "", false)
  end

  defp separar([caracter | resto], campos, actual, dentro) do
    separar(resto, campos, actual <> caracter, dentro)
  end



  defp valor_inventario(producto), do: producto.precio * producto.cantidad

  defp generar_reporte(productos) do
    valor_total = productos |> Enum.map(&valor_inventario/1) |> Enum.sum()
    mas_caro = Enum.max_by(productos, fn producto -> producto.precio end)
    mas_barato = Enum.min_by(productos, fn producto -> producto.precio end)

    lista =
      productos
      |> Enum.sort_by(fn producto -> {-valor_inventario(producto), producto.nombre} end)
      |> Enum.with_index(1)
      |> Enum.map(fn {producto, posicion} ->
        "#{posicion}. #{producto.nombre}: #{dinero(valor_inventario(producto))} " <>
          "(#{dinero(producto.precio)} x #{producto.cantidad})"
      end)
      |> Enum.join("\n")

    """
    === Reporte de inventario ===
    Valor total del inventario: #{dinero(valor_total)}
    Producto más caro: #{mas_caro.nombre} (#{dinero(mas_caro.precio)})
    Producto más barato: #{mas_barato.nombre} (#{dinero(mas_barato.precio)})

    Productos ordenados por valor en inventario (mayor a menor):
    #{lista}
    """
  end

  defp dinero(valor), do: :erlang.float_to_binary(valor * 1.0, decimals: 2)


  defp guardar_errores([], ruta), do: File.write!(ruta, "No se encontraron líneas inválidas.\n")

  defp guardar_errores(errores, ruta) do
    texto =
      errores
      |> Enum.map(fn {numero, motivo} -> "Línea #{numero}: #{motivo}\n" end)
      |> Enum.join()

    File.write!(ruta, texto)
  end


  defp mostrar_resultado({:ok, mensaje}), do: IO.puts(mensaje)
  defp mostrar_resultado({:error, motivo}), do: IO.puts("Error: #{motivo}")

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

Inventario.main()
