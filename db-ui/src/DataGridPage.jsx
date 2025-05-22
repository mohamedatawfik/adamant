import React, { useEffect, useState } from "react";
import { DataGridPremium } from "@mui/x-data-grid-premium";
import { TextField, MenuItem, Button, FormControl } from "@mui/material";

function DataGridPage() {
  const [tables, setTables] = useState([]);
  const [selectedTable, setSelectedTable] = useState("");
  const [rows, setRows] = useState([]);
  const [columns, setColumns] = useState([]);
  const [density, setDensity] = useState("compact");

  // Fetch table list from the backend
  useEffect(() => {
    fetch("/api/tables")
      .then((response) => response.json())
      .then((data) => {
        setTables(data);
        if (data.length > 0) setSelectedTable(data[0]);
      })
      .catch((err) => console.error("Error fetching table list:", err));
  }, []);

  // Fetch data and column information of the selected table
  useEffect(() => {
    if (!selectedTable) return;

    fetch(`/api/data/${selectedTable}`)
      .then((response) => response.json())
      .then((data) => {
        const rowsWithId = data.map((row, index) => ({
          id: index + 1,
          ...row,
        }));
        setRows(rowsWithId);
      })
      .catch((err) => console.error("Error fetching table data:", err));

    fetch(`/api/columns/${selectedTable}`)
      .then((response) => response.json())
      .then((columnData) => {
        const formattedColumns = [

          ...columnData.map((column) => ({
            field: column.name,
            headerName: column.name.charAt(0).toUpperCase() + column.name.slice(1),
            editable: true,
            type: /int|decimal|float|double/.test(column.type) ? "number" : "text",
          })),
        ];
        setColumns(formattedColumns);
      })
      .catch((err) => console.error("Error fetching column information:", err));
  }, [selectedTable]);

  const gridApiRef = React.useRef(null);

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        width: "100%",
        height: "100%",
        overflowX: "auto",
      }}
    >
      <div style={{ display: "flex", gap: "10px", marginBottom: "30px", padding: "5px" }}>
        {/* Table selection with TextField */}
        <FormControl style={{ minWidth: 500 }}>
          <TextField
            select
            label="Select Table"
            value={selectedTable}
            onChange={(e) => setSelectedTable(e.target.value)}
          >
            {tables.map((table) => (
              <MenuItem key={table} value={table}>
                {table}
              </MenuItem>
            ))}
          </TextField>
        </FormControl>

        {/* Export Buttons */}
        <Button variant="contained" onClick={() => gridApiRef.current.exportDataAsCsv()}>
          Export as CSV
        </Button>
        <Button variant="contained" onClick={() => gridApiRef.current.exportDataAsExcel()}>
          Export as Excel
        </Button>

        {/* Grid density selection with TextField */}
        <FormControl style={{ minWidth: 150 }}>
          <TextField
            select
            label="Grid Density"
            value={density}
            onChange={(e) => setDensity(e.target.value)}
          >
            <MenuItem value="compact">Compact</MenuItem>
            <MenuItem value="standard">Standard</MenuItem>
            <MenuItem value="comfortable">Comfortable</MenuItem>
          </TextField>
        </FormControl>
      </div>

      <div style={{ height: "700px", overflow: "auto", overflowX: "auto" }}>
        <DataGridPremium
          rows={rows}
          columns={columns}
          pageSize={10}
          rowsPerPageOptions={[10, 20, 50]}
          checkboxSelection
          disableSelectionOnClick
          experimentalFeatures={{ newEditingApi: true }}
          density={density}
          apiRef={gridApiRef}
        />
      </div>
    </div>
  );
}

export default DataGridPage;
