Attribute VB_Name = "Recaudaciones"
Option Explicit

Public Sub ActualizarFormato()
    CopiarRecaudaciones True
End Sub

Public Sub CopiarRecaudaciones(Optional ByVal MostrarMensaje As Boolean = True)
    Dim origen As Worksheet, destino As Worksheet
    Dim tablaOrigen As ListObject, tablaDestino As ListObject
    Dim columnas As Object, mapeo As Object
    Dim ultima As Range, bloque As Range, salida As Range
    Dim columna As ListColumn, clave As String, faltantes As String
    Dim filaDatos As Long, ultimaFila As Long, cantidad As Long
    Dim indice As Variant, colOrigen As Long, colDestino As Long
    Dim eventos As Boolean, pantalla As Boolean, descripcion As String
    eventos = Application.EnableEvents
    pantalla = Application.ScreenUpdating
    On Error GoTo Fallo
    Set origen = ThisWorkbook.Worksheets("Datos")
    Set destino = ThisWorkbook.Worksheets("Formato")
    Set tablaOrigen = origen.ListObjects("Tabla2")
    Set tablaDestino = destino.ListObjects("Tabla1")
    Set columnas = CreateObject("Scripting.Dictionary")
    columnas.CompareMode = vbTextCompare
    Set mapeo = CreateObject("Scripting.Dictionary")
    For Each columna In tablaOrigen.ListColumns
        clave = Trim$(columna.Name)
        If columnas.Exists(clave) Then Err.Raise vbObjectError + 1, , "Encabezado duplicado en DATOS: " & clave
        columnas.Add clave, columna.Range.Column
    Next columna
    For Each columna In tablaDestino.ListColumns
        clave = Trim$(columna.Name)
        If columnas.Exists(clave) Then
            mapeo.Add columna.Range.Column, columnas(clave)
        ElseIf Not EsColumnaVacia(clave) Then
            faltantes = faltantes & vbCrLf & clave
        End If
    Next columna
    If Len(faltantes) > 0 Then Err.Raise vbObjectError + 2, , "Faltan columnas en DATOS:" & faltantes
    If mapeo.Count = 0 Then Err.Raise vbObjectError + 3, , "No se encontraron columnas coincidentes."
    filaDatos = tablaOrigen.HeaderRowRange.Row + 1
    Set bloque = origen.Range(origen.Cells(filaDatos, tablaOrigen.Range.Column), origen.Cells(origen.Rows.Count, tablaOrigen.Range.Column + tablaOrigen.ListColumns.Count - 1))
    Set ultima = bloque.Find(What:="*", After:=bloque.Cells(1, 1), LookIn:=xlFormulas, LookAt:=xlPart, SearchOrder:=xlByRows, SearchDirection:=xlPrevious, MatchCase:=False, SearchFormat:=False)
    If ultima Is Nothing Then
        cantidad = 0
    Else
        ultimaFila = ultima.Row
        cantidad = ultimaFila - filaDatos + 1
    End If
    If cantidad + tablaDestino.HeaderRowRange.Row > destino.Rows.Count Then Err.Raise vbObjectError + 4, , "Los registros superan el limite de filas de FORMATO."
    Application.ScreenUpdating = False
    Application.EnableEvents = False
    ' Validar antes de reemplazar el resultado de la transferencia anterior.
    For Each indice In mapeo.Keys
        colDestino = CLng(indice)
        ultimaFila = destino.Cells(destino.Rows.Count, colDestino).End(xlUp).Row
        If ultimaFila > tablaDestino.HeaderRowRange.Row Then
            destino.Range(destino.Cells(tablaDestino.HeaderRowRange.Row + 1, colDestino), destino.Cells(ultimaFila, colDestino)).ClearContents
        End If
    Next indice
    tablaDestino.Resize tablaDestino.HeaderRowRange.Resize(IIf(cantidad = 0, 2, cantidad + 1), tablaDestino.ListColumns.Count)
    If cantidad > 0 Then
        For Each indice In mapeo.Keys
            colDestino = CLng(indice)
            colOrigen = CLng(mapeo(indice))
            Set bloque = origen.Cells(filaDatos, colOrigen).Resize(cantidad, 1)
            Set salida = destino.Cells(tablaDestino.HeaderRowRange.Row + 1, colDestino).Resize(cantidad, 1)
            bloque.Copy
            salida.PasteSpecial Paste:=xlPasteValuesAndNumberFormats
        Next indice
    End If
    Application.CutCopyMode = False
    Application.EnableEvents = eventos
    Application.ScreenUpdating = pantalla
    If MostrarMensaje Then MsgBox cantidad & " registros transferidos a FORMATO.", vbInformation, "Libro de Recaudaciones"
    Exit Sub
Fallo:
    descripcion = Err.Description
    Application.CutCopyMode = False
    Application.EnableEvents = eventos
    Application.ScreenUpdating = pantalla
    If MostrarMensaje Then
        MsgBox "No se pudo completar la transferencia: " & descripcion, vbExclamation, "Libro de Recaudaciones"
    Else
        Err.Raise vbObjectError + 10, "CopiarRecaudaciones", descripcion
    End If
End Sub

Private Function EsColumnaVacia(ByVal nombre As String) As Boolean
    Dim sufijo As String, i As Long
    If LCase$(Left$(nombre, 7)) <> "columna" Then Exit Function
    sufijo = Mid$(nombre, 8)
    If Len(sufijo) = 0 Then Exit Function
    For i = 1 To Len(sufijo)
        If Mid$(sufijo, i, 1) < "0" Or Mid$(sufijo, i, 1) > "9" Then Exit Function
    Next i
    EsColumnaVacia = True
End Function

' ============================================================================
' MACRO NUEVA: Transferir datos de DatosHubContable a FormatoBD
' ============================================================================
' Ejecutar desde el botón en la hoja "DatosHubContable"
' Copia todos los campos de TablaDatosHubContable a TablaFormatoDB
' excluyendo: IdContabilizacion, Contabilizacion, FechaContabilizacion
' ============================================================================

Public Sub TransferirDatosHubAFormato()
    TransferirDatosHub True
End Sub

Public Sub TransferirDatosHub(Optional ByVal MostrarMensaje As Boolean = True)
    Dim origen As Worksheet, destino As Worksheet
    Dim tablaOrigen As ListObject, tablaDestino As ListObject
    Dim columnas As Object, mapeo As Object
    Dim ultima As Range, bloque As Range, salida As Range
    Dim columna As ListColumn, clave As String, faltantes As String
    Dim filaDatos As Long, ultimaFila As Long, cantidad As Long
    Dim indice As Variant, colOrigen As Long, colDestino As Long
    Dim eventos As Boolean, pantalla As Boolean, descripcion As String
    Dim colExcluida As Long
    
    ' Columnas que NO se copian (se dejan en blanco)
    Const COL_ID_CONTABILIZACION As String = "IdContabilizacion"
    Const COL_CONTABILIZACION As String = "Contabilizacion"
    Const COL_FECHA_CONTABILIZACION As String = "FechaContabilizacion"
    
    eventos = Application.EnableEvents
    pantalla = Application.ScreenUpdating
    
    On Error GoTo Fallo
    
    ' PASO 1: Definir hojas y tablas de origen y destino
    Set origen = ThisWorkbook.Worksheets("DatosHubContable")
    Set destino = ThisWorkbook.Worksheets("FormatoBD")
    Set tablaOrigen = origen.ListObjects("TablaDatosHubContable")
    Set tablaDestino = destino.ListObjects("TablaFormatoDB")
    
    ' PASO 2: Indexar columnas del origen por nombre
    Set columnas = CreateObject("Scripting.Dictionary")
    columnas.CompareMode = vbTextCompare
    Set mapeo = CreateObject("Scripting.Dictionary")
    
    For Each columna In tablaOrigen.ListColumns
        clave = Trim$(columna.Name)
        If columnas.Exists(clave) Then Err.Raise vbObjectError + 1, , "Encabezado duplicado en DatosHubContable: " & clave
        columnas.Add clave, columna.Range.Column
    Next columna
    
    ' PASO 3: Mapear columnas del destino con las del origen
    '          Excluyendo las 3 columnas que no se copian
    For Each columna In tablaDestino.ListColumns
        clave = Trim$(columna.Name)
        
        ' Excluir las 3 columnas: dejar en blanco
        If LCase$(clave) = LCase$(COL_ID_CONTABILIZACION) Or _
           LCase$(clave) = LCase$(COL_CONTABILIZACION) Or _
           LCase$(clave) = LCase$(COL_FECHA_CONTABILIZACION) Then
            ' No agregar al mapeo (se deja en blanco)
        ElseIf columnas.Exists(clave) Then
            mapeo.Add columna.Range.Column, columnas(clave)
        ElseIf Not EsColumnaVacia(clave) Then
            faltantes = faltantes & vbCrLf & clave
        End If
    Next columna
    
    If Len(faltantes) > 0 Then Err.Raise vbObjectError + 2, , "Faltan columnas en DatosHubContable:" & faltantes
    If mapeo.Count = 0 Then Err.Raise vbObjectError + 3, , "No se encontraron columnas coincidentes."
    
    ' PASO 4: Contar registros en origen
    filaDatos = tablaOrigen.HeaderRowRange.Row + 1
    Set bloque = origen.Range(origen.Cells(filaDatos, tablaOrigen.Range.Column), _
                             origen.Cells(origen.Rows.Count, tablaOrigen.Range.Column + tablaOrigen.ListColumns.Count - 1))
    Set ultima = bloque.Find(What:="*", After:=bloque.Cells(1, 1), LookIn:=xlFormulas, _
                             LookAt:=xlPart, SearchOrder:=xlByRows, SearchDirection:=xlPrevious, _
                             MatchCase:=False, SearchFormat:=False)
    If ultima Is Nothing Then
        cantidad = 0
    Else
        ultimaFila = ultima.Row
        cantidad = ultimaFila - filaDatos + 1
    End If
    
    If cantidad + tablaDestino.HeaderRowRange.Row > destino.Rows.Count Then
        Err.Raise vbObjectError + 4, , "Los registros superan el limite de filas de FormatoBD."
    End If
    
    ' PASO 5: Preparar destino (limpiar datos existentes)
    Application.ScreenUpdating = False
    Application.EnableEvents = False
    
    ' Limpiar datos previos de TablaFormatoDB
    If tablaDestino.DataBodyRange Is Nothing Then
        ' La tabla ya está vacía
    Else
        tablaDestino.DataBodyRange.Delete
    End If
    
    ' Redimensionar tabla destino
    tablaDestino.Resize tablaDestino.HeaderRowRange.Resize(IIf(cantidad = 0, 2, cantidad + 1), tablaDestino.ListColumns.Count)
    
    ' PASO 6: Copiar datos mapeados
    If cantidad > 0 Then
        For Each indice In mapeo.Keys
            colDestino = CLng(indice)
            colOrigen = CLng(mapeo(indice))
            Set bloque = origen.Cells(filaDatos, colOrigen).Resize(cantidad, 1)
            Set salida = destino.Cells(tablaDestino.HeaderRowRange.Row + 1, colDestino).Resize(cantidad, 1)
            bloque.Copy
            salida.PasteSpecial Paste:=xlPasteValuesAndNumberFormats
        Next indice
    End If
    
    Application.CutCopyMode = False
    Application.EnableEvents = eventos
    Application.ScreenUpdating = pantalla
    
    If MostrarMensaje Then
        MsgBox cantidad & " registros transferidos a FormatoBD." & vbCrLf & vbCrLf & _
               "Campos excluidos (en blanco):" & vbCrLf & _
               "- IdContabilizacion" & vbCrLf & _
               "- Contabilizacion" & vbCrLf & _
               "- FechaContabilizacion", _
               vbInformation, "Libro de Recaudaciones"
    End If
    
    Exit Sub
    
Fallo:
    descripcion = Err.Description
    Application.CutCopyMode = False
    Application.EnableEvents = eventos
    Application.ScreenUpdating = pantalla
    If MostrarMensaje Then
        MsgBox "No se pudo completar la transferencia: " & descripcion, vbExclamation, "Libro de Recaudaciones"
    Else
        Err.Raise vbObjectError + 10, "TransferirDatosHub", descripcion
    End If
End Sub

Private Function EsColumnaVacia(ByVal nombre As String) As Boolean
    Dim sufijo As String, i As Long
    If LCase$(Left$(nombre, 7)) <> "columna" Then Exit Function
    sufijo = Mid$(nombre, 8)
    If Len(sufijo) = 0 Then Exit Function
    For i = 1 To Len(sufijo)
        If Mid$(sufijo, i, 1) < "0" Or Mid$(sufijo, i, 1) > "9" Then Exit Function
    Next i
    EsColumnaVacia = True
End Function
