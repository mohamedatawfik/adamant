import React, { useEffect, useState } from "react";
import { DataGridPremium } from "@mui/x-data-grid-premium";
import { Select, MenuItem, FormControl, InputLabel } from "@mui/material";

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

  // Daten der ausgewählten Tabelle abrufen
  useEffect(() => {
    if (!selectedTable) return;

    fetch(`http://localhost:3001/api/data/${selectedTable}`)
      .then((response) => response.json())
      .then((data) => {
        if (data.length > 0) {
          const cols = Object.keys(data[0]).map((key) => ({
            field: key,
            headerName: key.charAt(0).toUpperCase() + key.slice(1),
            flex: 1, // Flexible Spalten
          }));
          setColumns(cols);

          const rowsWithId = data.map((row, index) => ({
            id: index,
            ...row,
          }));
          setRows(rowsWithId);
        } else {
          setColumns([]);
          setRows([]);
        }
      })
      .catch((err) => console.error("Fehler beim Abrufen der Tabellendaten:", err));
  }, [selectedTable]);

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        width: "100vw", // Volle Breite
        height: "100vh", // Volle Höhe
        margin: 0,
        padding: 0,
        boxSizing: "border-box",
      }}
    >
      <FormControl fullWidth style={{ margin: "10px 0" }}>
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
      <div style={{ flex: 1, margin: 0 }}>
        <DataGridPremium
          rows={rows}
          columns={columns}
          pageSize={10}
          rowsPerPageOptions={[10, 20, 50]}
          checkboxSelection
          disableSelectionOnClick
          experimentalFeatures={{ newEditingApi: true }}
          sx={{
            width: "100%",
            height: "100%",
            '& .MuiDataGrid-cell': { whiteSpace: 'nowrap' },
          }}
        />
      </div>
    </div>
  );
}

export default App;

