import { useState, useMemo } from "react";
import { AgGridReact } from "ag-grid-react";

import "ag-grid-community/styles/ag-grid.css";
import "ag-grid-community/styles/ag-theme-alpine.css";

const DataTable = ({data}) => {
	const defaultColDef = useMemo(() => {
		return {
			editable: true,
			sortable: true,
			resizable: true,
			filter: true,
			flex: 1,
			minWidth: 100,
		};
	}, []);

	const defs = data[0]
		? Object.keys(data[0]).map((key) => ({
				field: key,
				headerName: key.charAt(0).toUpperCase() + key.slice(1),
				width: 150,
		  }))
		: [];

	const [rowData, setRowData] = useState(data);
	const [columnDefs, setColumnDefs] = useState(defs);

	return (
		<div
			className="ag-theme-alpine"
			style={{
				height: "80vh",
				width: "100%",
			}}
		>
			<AgGridReact
				rowData={rowData}
				columnDefs={columnDefs}
				defaultColDef={defaultColDef}
				pagination={true}
				readOnlyEdit={true}
				suppressClickEdit={true}
				editable={false}
			></AgGridReact>
		</div>
	);
};

export default DataTable;
