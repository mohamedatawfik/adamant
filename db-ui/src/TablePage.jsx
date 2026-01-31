import React, { useEffect, useState } from "react";
import { DataGridPremium, useGridApiRef } from "@mui/x-data-grid-premium";
import { Button, TextField, MenuItem } from "@mui/material";

function JoinTablePage() {
  const [tables, setTables] = useState([]);
  const [table1, setTable1] = useState("");
  const [table2, setTable2] = useState("");
  const [columns1, setColumns1] = useState([]);
  const [columns2, setColumns2] = useState([]);
  const [column1, setColumn1] = useState("");
  const [column2, setColumn2] = useState("");
  const [rows, setRows] = useState([]);
  const [columns, setColumns] = useState([]);
  const [density, setDensity] = useState("compact"); // Default density set to "compact"

  const gridApiRef = useGridApiRef(); // Hook to manage the grid API

  // Fetch table list from backend
  useEffect(() => {
    fetch("/api/tables")
      .then((response) => response.json())
      .then((data) => setTables(data))
      .catch((err) => console.error("Error fetching tables:", err));
  }, []);

  // Fetch columns for table 1
  useEffect(() => {
    if (!table1) return;

    fetch(`/api/columns/${table1}`)
      .then((response) => response.json())
      .then((data) => setColumns1(data.map((col) => col.name)))
      .catch((err) => console.error("Error fetching columns for table 1:", err));
  }, [table1]);

  // Fetch columns for table 2
  useEffect(() => {
    if (!table2) return;

    fetch(`/api/columns/${table2}`)
      .then((response) => response.json())
      .then((data) => setColumns2(data.map((col) => col.name)))
      .catch((err) => console.error("Error fetching columns for table 2:", err));
  }, [table2]);

  // Fetch join data
  const fetchJoinData = () => {
    if (!table1 || !table2 || !column1 || !column2) {
      alert("Please fill all fields before performing the join.");
      return;
    }

    fetch(
      `/api/left-join?table1=${table1}&table2=${table2}&column1=${column1}&column2=${column2}`
    )
      .then((response) => response.json())
      .then(({ columns, data }) => {
        if (data.length === 0) {
          alert("No data available for the join.");
        }
        const rowsWithId = data.map((row, index) => ({
          id: index + 1,
          ...row,
        }));

        const allColumns = columns.map((field) => ({
          field,
          headerName: field.charAt(0).toUpperCase() + field.slice(1),
          editable: true,
        }));

        setRows(rowsWithId);
        setColumns(allColumns);
      })
      .catch((err) => console.error("Error fetching join data:", err));
  };

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        width: "100%",
        height: "100%",
      }}
    >
      <div style={{ display: "flex", gap: "10px", marginBottom: "10px" }}>
        {/* Select table 1 */}
        <TextField
          select
          label="Table 1"
          value={table1}
          onChange={(e) => setTable1(e.target.value)}
          style={{ minWidth: 200 }}
        >
          {tables.map((table) => (
            <MenuItem key={table} value={table}>
              {table}
            </MenuItem>
          ))}
        </TextField>

        {/* Select table 2 */}
        <TextField
          select
          label="Table 2"
          value={table2}
          onChange={(e) => setTable2(e.target.value)}
          style={{ minWidth: 200 }}
        >
          {tables.map((table) => (
            <MenuItem key={table} value={table}>
              {table}
            </MenuItem>
          ))}
        </TextField>

        {/* Select column from table 1 */}
        <TextField
          select
          label="Column from Table 1"
          value={column1}
          onChange={(e) => setColumn1(e.target.value)}
          style={{ minWidth: 200 }}
          variant="outlined"
          disabled={!columns1.length}
        >
          {columns1.map((col) => (
            <MenuItem key={col} value={col}>
              {col}
            </MenuItem>
          ))}
        </TextField>

        {/* Select column from table 2 */}
        <TextField
          select
          label="Column from Table 2"
          value={column2}
          onChange={(e) => setColumn2(e.target.value)}
          style={{ minWidth: 200 }}
          disabled={!columns2.length}
        >
          {columns2.map((col) => (
            <MenuItem key={col} value={col}>
              {col}
            </MenuItem>
          ))}
        </TextField>

        {/* Fetch join data button */}
        <Button
          variant="contained"
          onClick={fetchJoinData}
          style={{ minWidth: 150, backgroundColor: '#3f51b5', color: '#fff', '&:hover': { backgroundColor: '#303f9f' }}}
        >
          Fetch Data
        </Button>

        {/* Export buttons - Visible only when data is loaded */}
        {rows.length > 0 && (
          <>
            <Button
              variant="contained"
              onClick={() => gridApiRef.current.exportDataAsCsv()}
              style={{ minWidth: 150, backgroundColor: '#3f51b5', color: '#fff', '&:hover': { backgroundColor: '#303f9f' }}}
            >
              Export as CSV
            </Button>
            <Button
              variant="contained"
              onClick={() => gridApiRef.current.exportDataAsExcel()}
              style={{ minWidth: 150, backgroundColor: '#3f51b5', color: '#fff', '&:hover': { backgroundColor: '#303f9f' }}}
            >
              Export as Excel
            </Button>
          </>
        )}

        {/* Grid density selection */}
        <TextField
          select
          label="Grid Density"
          value={density}
          onChange={(e) => setDensity(e.target.value)}
          style={{ minWidth: 150 }}
        >
          <MenuItem value="compact">Compact</MenuItem>
          <MenuItem value="standard">Standard</MenuItem>
          <MenuItem value="comfortable">Comfortable</MenuItem>
        </TextField>
      </div>

      <div style={{ height: "700px", overflow: "auto" }}>
        <DataGridPremium
          rows={rows}
          columns={columns}
          pageSize={10}
          checkboxSelection
          density={density}
          apiRef={gridApiRef}
        />
      </div>
    </div>
  );
}

export default JoinTablePage;
