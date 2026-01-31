import React, { useEffect, useState } from "react";
import { DataGridPremium } from "@mui/x-data-grid-premium";
import { Select, MenuItem, FormControl, InputLabel, Button } from "@mui/material";

function App() {
  const [tables, setTables] = useState([]);
  const [selectedTable, setSelectedTable] = useState("");
  const [rows, setRows] = useState([]);
  const [columns, setColumns] = useState([]);

  // Tabellenliste vom Backend abrufen
  useEffect(() => {
    fetch("http://localhost:3001/api/tables")
      .then((response) => response.json())
      .then((data) => {
        setTables(data);
        if (data.length > 0) setSelectedTable(data[0]);
      })
      .catch((err) => console.error("Fehler beim Abrufen der Tabellen:", err));
  }, []);

  // Daten und Spalteninformationen der ausgewählten Tabelle abrufen
  useEffect(() => {
    if (!selectedTable) return;

    fetch(`http://localhost:3001/api/data/${selectedTable}`)
      .then((response) => response.json())
      .then((data) => {
        const rowsWithId = data.map((row, index) => ({
          id: index + 1,
          number: index + 1,
          ...row,
        }));
        setRows(rowsWithId);
      })
      .catch((err) => console.error("Fehler beim Abrufen der Tabellendaten:", err));

    fetch(`http://localhost:3001/api/columns/${selectedTable}`)
      .then((response) => response.json())
      .then((columnData) => {
        const formattedColumns = [
          {
            field: "number",
            headerName: "Nr.",
            width: 70,
            sortable: false,
          },
          ...columnData.map((column) => ({
            field: column.name,
            headerName: column.name.charAt(0).toUpperCase() + column.name.slice(1),
            flex: 1,
            editable: true,
            type: /int|decimal|float|double/.test(column.type) ? "number" : "text",
          })),
        ];
        setColumns(formattedColumns);
      })
      .catch((err) => console.error("Fehler beim Abrufen der Spalteninformationen:", err));
  }, [selectedTable]);

  // Exportfunktion
  const handleExport = (format) => {
    const options = {
      fileName: `${selectedTable}_Export`,
      selectedRowsOnly: true, // Nur ausgewählte Zeilen exportieren
    };

    if (format === "csv") {
      gridApiRef.current.exportDataAsCsv(options);
    } else if (format === "excel") {
      gridApiRef.current.exportDataAsExcel(options);
    }
  };

  // Referenz für die Grid-API
  const gridApiRef = React.useRef(null);

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        width: "100vw",
        height: "100vh",
      }}
    >
      {/* Container für Dropdown und Buttons */}
      <div
        style={{
          width: "90%", // Gleiche Breite wie das Grid
          margin: "0 auto", // Zentriert den Container horizontal
          marginBottom: "10px", // Abstand nach unten
        }}
      >
        {/* Tabellen-Dropdown */}
        <FormControl fullWidth style={{ margin: "20px 0" }}>
          <InputLabel id="table-select-label">Select Table</InputLabel>
          <Select
            labelId="table-select-label"
            value={selectedTable}
            onChange={(e) => setSelectedTable(e.target.value)}
          >
            {tables.map((table) => (
              <MenuItem key={table} value={table}>
                {table}
              </MenuItem>
            ))}
          </Select>
        </FormControl>

        {/* Export-Buttons */}
        <div style={{ display: "flex", gap: "10px" }}>
          <Button variant="contained" onClick={() => handleExport("csv")}>
            Export als CSV
          </Button>
          <Button variant="contained" onClick={() => handleExport("excel")}>
            Export als Excel
          </Button>
        </div>
      </div>

      {/* Container mit Scrollbalken */}
      <div
        style={{
          width: "90%", // Gleiche Breite wie das Dropdown
          height: "700px", // Feste Höhe des Containers
          overflow: "auto", // Scrollbalken aktivieren, wenn Inhalte den Container überlaufen
          margin: "0 auto", // Zentriert den Container horizontal
          border: "1px solid #ccc", // Optional: Rahmen um den Container
          padding: "10px", // Optional: Innenabstand
        }}
      >
        <DataGridPremium
          rows={rows}
          columns={columns}
          pageSize={10}
          rowsPerPageOptions={[10, 20, 50]}
          checkboxSelection
          disableSelectionOnClick
          experimentalFeatures={{ newEditingApi: true }}
          apiRef={gridApiRef}
          sx={{
            "& .MuiDataGrid-root": {
              border: "none",
            },
          }}
        />
      </div>
    </div>
  );
}

export default App;
