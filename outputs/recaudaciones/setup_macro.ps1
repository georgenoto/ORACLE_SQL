$ErrorActionPreference = 'Stop'
$taskRoot = 'C:\D\DATOS TRABAJO\NUEVO CORE\ORACLE_SQL'
$taskSource = Join-Path $taskRoot 'EXCEL UTILITARIOS\Formato Libro Recaudaciones.xlsx'
$taskOutput = Join-Path $taskRoot 'EXCEL UTILITARIOS\Formato Libro Recaudaciones.xlsm'
if (Test-Path -LiteralPath $taskOutput) { throw 'El archivo XLSM ya existe; no se sobrescribio.' }
$taskExcel = New-Object -ComObject Excel.Application
try {
    $taskExcel.Visible = $false
    $taskBook = $taskExcel.Workbooks.Open($taskSource)
    if ($taskBook.ReadOnly) { throw 'El archivo original esta abierto en modo solo lectura.' }
    $taskData = $taskBook.Worksheets.Item('Datos')
    $taskData.Rows.Item('1:3').Insert() | Out-Null
    $taskData.Rows.Item('1:3').RowHeight = 20
    $taskButton = $taskData.Buttons().Add(5, 5, 195, 43)
    $taskButton.Name = 'btnActualizarFormato'
    $taskButton.Caption = 'Actualizar FORMATO'
    $taskButton.OnAction = "'Formato Libro Recaudaciones.xlsm'!ActualizarFormato"
    $taskButton.Placement = 3
    $taskData.Range('D1').Value2 = 'Pegue los registros en DATOS y pulse Actualizar FORMATO.'
    $taskData.Range('D2').Value2 = 'Cada ejecucion reemplaza el resultado anterior.'
    $taskData.Activate()
    $taskData.Range('A5').Select()
    $taskBook.SaveAs($taskOutput, 52)
    $taskBook.Close($false)
    Write-Output $taskOutput
} finally {
    $taskExcel.Quit()
    [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($taskExcel)
}
