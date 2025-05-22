import React, { useEffect, useState } from "react";
import { DataGridPremium, GridToolbarContainer, GridPagination } from "@mui/x-data-grid-premium";
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

  // Custom Toolbar mit Pagination
  const CustomToolbar = () => (
    <GridToolbarContainer>
      <GridPagination
        sx={{
          "& .MuiTablePagination-root": {
            marginTop: "8px", // Optische Trennung
          },
        }}
      />
    </GridToolbarContainer>
  );

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        width: "100vw",
        height: "100vh",
      }}
    >
      {/* Tabellen-Dropdown */}
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

      {/* DataGridPremium mit Pagination oben */}
      <div style={{ flex: 1, margin: 0 }}>
        <DataGridPremium
          rows={rows}
          columns={columns}
          pageSize={10}
          rowsPerPageOptions={[10, 20, 50]}
          checkboxSelection
          disableSelectionOnClick
          experimentalFeatures={{ newEditingApi: true }}
          components={{
            Toolbar: CustomToolbar, // Toolbar oben mit Pagination
          }}
          sx={{
            "& .MuiDataGrid-root": {
              border: "none", // Entfernt Standardrahmen
            },
          }}
        />
      </div>
    </div>
  );
}

export default App;
